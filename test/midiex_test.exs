defmodule MidiexTest do
  use ExUnit.Case, async: true
  doctest Midiex

  test "create a virtual output port" do
    port_name = "My Virtual Output"

    # Connection
    virtual_out_conn = Midiex.create_virtual_output(port_name)
    assert is_struct(virtual_out_conn, Midiex.OutConn), "expected a %Midiex.OutConn{} struct"
    assert virtual_out_conn.name == port_name, "expected %Midiex.OutConn{} name to be \"#{port_name}\""

    # Port visible
    input_port = Midiex.ports(port_name, :input) |> List.first()
    assert is_struct(input_port, Midiex.MidiPort), "expected a %Midiex.MidiPort{} struct"
    assert input_port.name == port_name, "expected %Midiex.MidiPort{} name to be \"#{port_name}\""
    assert input_port.direction == :input, "expected %Midiex.MidiPort{} direction to be :input"
  end

  test "create a virtual input port" do
    port_name = "My Virtual Input"

    virual_in_port = Midiex.create_virtual_input(port_name)
    assert is_struct(virual_in_port, Midiex.VirtualMidiPort), "expected a %Midiex.VirtualMidiPort{} struct"
    assert virual_in_port.name == port_name, "expected %Midiex.VirtualMidiPort{} name to be \"#{port_name}\""
    assert virual_in_port.direction == :input, "expected %Midiex.VirtualMidiPort{} direction to be :input"
  end

  test "sysex test" do
    port_name = "SysEx test"
    :persistent_term.put(:sysex_msg, [])

    # Create port
    out_conn = Midiex.create_virtual_output(port_name)

    # Setup listener
    input_port = Midiex.ports("SysEx test", :input)
    {:ok, pid} = Midiex.Listener.start(port: input_port)
    Midiex.Listener.add_handler(pid, fn msg -> :persistent_term.put(:sysex_msg, msg.data) end)

    # Create SysEx message, using Roland device id, and send it
    roland_device_id = 0x41
    bin_message = <<1, 2, 3, 4>>
    message = Midiex.Message.sysex(roland_device_id, bin_message)
    Midiex.send_msg(out_conn, message) # sends [240, 65, 1, 2, 3, 4, 247]

    :timer.sleep(50) # delay for persistient term to be updated before asserting truth

    # Check if message data was added to persistent term
    assert :persistent_term.get(:sysex_msg) == [240, 65, 1, 2, 3, 4, 247], "expected message data to be equal to [240, 65, 1, 2, 3, 4, 247]"
  end

end
