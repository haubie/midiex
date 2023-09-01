defmodule MidiexTest do
  use ExUnit.Case, async: false
  doctest Midiex

  test "create a virtual output port" do
    port_name = "My Virtual Output"

    # Port  count
    %{input: initial_num_input_ports} = Midiex.port_count()

    # Connection
    virtual_out_conn = Midiex.create_virtual_output(port_name)
    assert is_struct(virtual_out_conn, Midiex.OutConn), "expected a %Midiex.OutConn{} struct"
    assert virtual_out_conn.name == port_name, "expected %Midiex.OutConn{} name to be \"#{port_name}\""

    # Input port count should be +1
    %{input: num_input_ports} = Midiex.port_count()
    assert num_input_ports == (initial_num_input_ports + 1), "expected the number of input ports to be \"#{initial_num_input_ports + 1}\""

    # Port visible
    input_port = Midiex.ports(port_name, :input) |> List.first()
    assert is_struct(input_port, Midiex.MidiPort), "expected a %Midiex.MidiPort{} struct"
    assert input_port.name == port_name, "expected %Midiex.MidiPort{} name to be \"#{port_name}\""
    assert input_port.direction == :input, "expected %Midiex.MidiPort{} direction to be :input"
  end

  test "create a virtual input port" do
    port_name = "My Virtual Input"

    # Port count
    %{output: initial_num_output_ports} = Midiex.port_count()

    virtual_in_port = Midiex.create_virtual_input(port_name)
    assert is_struct(virtual_in_port, Midiex.VirtualMidiPort), "expected a %Midiex.VirtualMidiPort{} struct"
    assert virtual_in_port.name == port_name, "expected %Midiex.VirtualMidiPort{} name to be \"#{port_name}\""
    assert virtual_in_port.direction == :input, "expected %Midiex.VirtualMidiPort{} direction to be :input"

    # Subscribe to the port, this will create an %Midiex.MidiPort{direction: :output}
    Midiex.subscribe(virtual_in_port)

    # Port visible
    output_port = Midiex.ports(port_name, :output) |> List.first()
    assert is_struct(output_port, Midiex.MidiPort), "expected a %Midiex.MidiPort{} struct"
    assert output_port.name == port_name, "expected %Midiex.MidiPort{} name to be \"#{port_name}\""
    assert output_port.direction == :output, "expected %Midiex.MidiPort{} direction to be :output"

    # Output port count should be +1
    %{output: num_output_ports} = Midiex.port_count()
    assert num_output_ports == (initial_num_output_ports + 1), "expected the number of output ports to be \"#{initial_num_output_ports + 1}\""

    # Clean up
    Midiex.unsubscribe(virtual_in_port)
  end

  # test "send and recieve MIDI messages" do

  #   port_name = "Midiex test port"
  #   :persistent_term.put(:midi_msg, [])

  #   # Create port
  #   out_conn = Midiex.create_virtual_output(port_name)

  #   # Setup listener
  #   input_port = Midiex.ports(port_name, :input)
  #   IO.inspect input_port, label: "IN PORT 1"
  #   {:ok, pid} = Midiex.Listener.start_link(port: input_port)
  #   Midiex.Listener.add_handler(pid, fn msg -> IO.inspect(msg.data, label: "MSG 1"); :persistent_term.put(:midi_msg, msg.data) end)

  #   # Create MIDI message and send it to the virual output
  #   message = Midiex.Message.note_on(:C3, 127)
  #   Midiex.send_msg(out_conn, message) # sends <<144, 48, 127>>

  #   :timer.sleep(25) # delay for persistient term to be updated before asserting truth

  #   # Check if message data was added to persistent term
  #   received_message = :persistent_term.get(:midi_msg)
  #   assert received_message == [144, 48, 127], "expected message data to be equal to [144, 48, 127], got #{inspect(received_message)}"

  #   # Clean up
  #   Midiex.Listener.unsubscribe(pid, input_port)
  #   Midiex.close(out_conn)
  #   GenServer.stop(pid)
  # end

  test "sysex and send and recieve MIDI message test" do
    port_name = "SysEx test"
    :persistent_term.put(:sysex_msg, [])

    # Create port
    out_conn = Midiex.create_virtual_output(port_name)

    # Setup listener
    input_port = Midiex.ports(port_name, :input)
    {:ok, pid} = Midiex.Listener.start_link(port: input_port)
    Midiex.Listener.add_handler(pid, fn msg -> :persistent_term.put(:sysex_msg, msg.data) end)

    # Create SysEx message, using Roland device id, and send it to the virual output
    roland_device_id = 0x41
    bin_message = <<1, 2, 3, 4>>
    message = Midiex.Message.sysex(roland_device_id, bin_message)
    Midiex.send_msg(out_conn, message) # sends [240, 65, 1, 2, 3, 4, 247]

    :timer.sleep(25) # delay for persistient term to be updated before asserting truth

    # Check if message data was added to persistent term
    received_message = :persistent_term.get(:sysex_msg)
    assert received_message == [240, 65, 1, 2, 3, 4, 247], "expected message data to be equal to [240, 65, 1, 2, 3, 4, 247], got #{inspect(received_message)}"

    # Clean-up
    Midiex.Listener.unsubscribe(pid, input_port)
    Midiex.close(out_conn)
    GenServer.stop(pid)
  end

end
