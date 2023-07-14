defmodule Midiex.MidiNotification do
  @moduledoc """
  A struct representing notifications of MIDI changes.

  This is currently only implemented on MacOS and is capturing added or removed messages only (e.g. a device or port has been added or removed).

  An example use of this is for hot swapping of devices, responding to if a device has been added or removed.

  The main fields are:
  - `notification_type:` which is of type `:added` or `:removed`
  - `name:` which is the same as the port name used in `%Midiex.MidiPort{}`
  - `direction:` which is the same as the port direction used in `%Midiex.MidiPort{}`.

  Additionally, the following fields have been included from **coreaudio** (MacOS):
  - `parent_name:` which may or may not be the same as the `name:` field above
  - `parent_type:` the 'parent type' reported by coreaudio, often `:entity`
  - `parent_id:` the unique numerical ID reported by coreaudio for the parent
  - `native_id:` the unique numerical ID reported by coreaudio for the port

  ## Example
  ```
  # KeyStep Pro keyboard has been hot-plugged into the Mac:
  %Midiex.MidiNotification{
    notification_type: :added,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 493507367,
    direction: :input
  }
  %Midiex.MidiNotification{
    notification_type: :added,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 2688501783,
    direction: :output
  }

  # KeyStep Pro keyboard has been unplugged into the Mac:
  %Midiex.MidiNotification{
    notification_type: :removed,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 493507367,
    direction: :input
  }
  %Midiex.MidiNotification{
    notification_type: :removed,
    parent_name: "KeyStep Pro",
    parent_id: 1384647386,
    parent_type: :entity,
    name: "KeyStep Pro",
    native_id: 2688501783,
    direction: :output
  }
  ```
  """
  defstruct ~w/notification_type parent_name parent_id parent_type name native_id direction/a

end
