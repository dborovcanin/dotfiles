//! Make niri tile like sway: a lone column fills the screen.
//!
//! niri keeps a column at its own width however many there are. This follows
//! the event stream and counts the tiled columns on every workspace. When a
//! workspace drops to one column, that column is widened to 100%. When a second
//! column joins a lone one, both are set to 50%, like a sway split. Widths are
//! only touched when the count changes, so manual resizes stick.
//!
//! Started from config/niri/config.kdl with spawn-at-startup.

use std::collections::{BTreeMap, HashMap};
use std::io;

use niri_ipc::socket::Socket;
use niri_ipc::state::{EventStreamStatePart, WindowsState};
use niri_ipc::{Action, Event, Request, Response, SizeChange};

/// Workspace id to {column index: a window in that column}.
type Columns = HashMap<u64, BTreeMap<usize, u64>>;

fn columns(state: &WindowsState) -> Columns {
    let mut result = Columns::new();
    for win in state.windows.values() {
        if win.is_floating {
            continue;
        }
        let (Some(ws), Some((column, _))) = (win.workspace_id, win.layout.pos_in_scrolling_layout)
        else {
            continue;
        };
        result.entry(ws).or_default().entry(column).or_insert(win.id);
    }
    result
}

fn set_width(id: u64, percent: f64) -> io::Result<()> {
    let action = Action::SetWindowWidth {
        id: Some(id),
        change: SizeChange::SetProportion(percent),
    };
    match Socket::connect()?.send(Request::Action(action))? {
        Ok(_) => Ok(()),
        Err(err) => Err(io::Error::other(err)),
    }
}

fn main() -> io::Result<()> {
    let mut socket = Socket::connect()?;
    match socket.send(Request::EventStream)? {
        Ok(Response::Handled) => {}
        Ok(other) => return Err(io::Error::other(format!("unexpected reply: {other:?}"))),
        Err(err) => return Err(io::Error::other(err)),
    }
    let mut read_event = socket.read_events();

    let mut state = WindowsState::default();
    // None until the first WindowsChanged, so windows already open are left alone.
    let mut counts: Option<HashMap<u64, usize>> = None;

    loop {
        let event = read_event()?;
        let initial = matches!(event, Event::WindowsChanged { .. }) && counts.is_none();
        let relevant = matches!(
            event,
            Event::WindowOpenedOrChanged { .. }
                | Event::WindowClosed { .. }
                | Event::WindowLayoutsChanged { .. }
        );
        if state.apply(event).is_some() || !(initial || relevant) {
            continue;
        }

        let current = columns(&state);
        let now: HashMap<u64, usize> = current.iter().map(|(ws, c)| (*ws, c.len())).collect();

        if let Some(before) = &counts {
            for (ws, cols) in &current {
                let (was, is) = (before.get(ws).copied().unwrap_or(0), cols.len());
                if was == is {
                    continue;
                }
                let result = match (was, is) {
                    (_, 1) => cols.values().try_for_each(|id| set_width(*id, 100.0)),
                    (1, 2) => cols.values().try_for_each(|id| set_width(*id, 50.0)),
                    _ => Ok(()),
                };
                if let Err(err) = result {
                    eprintln!("niri-autofill: {err}");
                }
            }
        }
        counts = Some(now);
    }
}
