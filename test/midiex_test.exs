defmodule MidiexTest do
  @moduledoc """
  Tests are organised into four categories using ExUnit tags:
  - **Standard (No Tag)** - for all supported platforms (macOS, Linux, Windows)
  - `@tag :virtual_ports` - for macOS and Linux
  - `@tag :macos_only` - for macOS only
  - `@tag :windows_only` - for Windows only
  """
  use ExUnit.Case, async: false
  doctest Midiex

  # ####################################
  # General tests (all platforms)
  # ####################################

  test "port_count/0 returns correct map structure" do
    counts = Midiex.port_count()
    assert is_map(counts)
    assert Map.has_key?(counts, :input)
    assert Map.has_key?(counts, :output)
    assert is_integer(counts.input) and counts.input >= 0
    assert is_integer(counts.output) and counts.output >= 0
  end

  test "ports/0 and ports/1 return lists" do
    assert is_list(Midiex.ports())
    assert is_list(Midiex.ports(:input))
    assert is_list(Midiex.ports(:output))
  end

  test "ports/2 filters by name with strings and regexes" do
    # Generate a unique non-existent name to avoid collisions
    bogus_name = "NonExistentPort_#{System.unique_integer([:positive])}"
    assert Midiex.ports(bogus_name) == []
    assert Midiex.ports(bogus_name, :input) == []
    assert Midiex.ports(bogus_name, :output) == []

    # Search using a regex that matches nothing
    bogus_regex = Regex.compile!("BogusNameMatch_#{System.unique_integer([:positive])}")
    assert Midiex.ports(bogus_regex) == []
    assert Midiex.ports(bogus_regex, :input) == []
    assert Midiex.ports(bogus_regex, :output) == []
  end

  # ####################################
  # MIDI Message Helpers (Midiex.Message)
  # ####################################

  describe "Midiex.Message" do
    alias Midiex.Message, as: M

    test "note/1 converts representations to midi integers" do
      assert M.note(60) == 60
      assert M.note("C4") == 60
      assert M.note(:C4) == 60
      assert M.note(:A0) == 21
    end

    test "note_on/3 creates correct binary structure" do
      assert M.note_on(:C4) == <<144, 60, 127>>
      assert M.note_on("C4", 100) == <<144, 60, 100>>
      assert M.note_on(60, 127, channel: 5) == <<148, 60, 127>>
    end

    test "note_off/3 creates correct binary structure" do
      assert M.note_off(:C4) == <<128, 60, 123>>
      assert M.note_off("C4", 64) == <<128, 60, 64>>
      assert M.note_off(60, 100, channel: 16) == <<143, 60, 100>>
    end

    test "control_change/3 and program_change/2 create correct binaries" do
      # Volume on channel 0
      assert M.control_change(7, 100) == <<176, 7, 100>>
      # Pan on channel 1 (base 0)
      assert M.control_change(10, 64, channel: 2) == <<177, 10, 64>>

      assert M.program_change(5) == <<192, 5>>
      assert M.program_change(12, channel: 11) == <<202, 12>>
    end

    test "volume/2 and high-res options output on correct channels" do
      # Volume defaults to channel 0 (base 0)
      assert M.volume(100) == <<176, 7, 100>>
      # Explicit channel: 5 should map to channel 4 (base 0)
      assert M.volume(100, channel: 5) == <<180, 7, 100>>

      # 14-bit High-res volume
      assert M.volume(16383, high_res: true) == <<176, 7, 127, 176, 39, 127>>
    end

    test "aftertouch functions output correct byte-aligned structures" do
      # Channel Aftertouch: Status 0xD0, 2 bytes (no note argument)
      assert M.channel_aftertouch(90) == <<208, 90>>
      assert M.channel_aftertouch(110, channel: 3) == <<210, 110>>

      # Polyphonic Aftertouch: Status 0xA0, 3 bytes (note + pressure)
      assert M.polyphonic_aftertouch(:C4, 90) == <<160, 60, 90>>
      assert M.polyphonic_aftertouch("C4", 80, channel: 4) == <<163, 60, 80>>
    end

    test "pitch_bend/2 creates correct binary" do
      # Pitch bend uses 14-bit value where 8192 is center
      # LSB 0, MSB 64
      assert M.pitch_bend(8192) == <<224, 0, 64>>
      assert M.pitch_bend(0) == <<224, 0, 0>>
      assert M.pitch_bend(16383, channel: 3) == <<226, 127, 127>>
    end

    test "sysex/2 packages messages with F0 and F7 markers" do
      assert M.sysex(0x41, <<1, 2, 3, 4>>) == <<240, 0x41, 1, 2, 3, 4, 247>>
    end

    test "realtime system commands generate single status bytes" do
      assert M.clock() == <<248>>
      assert M.start() == <<250>>
      assert M.resume() == <<251>>
      assert M.stop() == <<252>>
      assert M.active_sense() == <<254>>
      assert M.reset() == <<255>>
    end
  end

  # ####################################
  # Virtual ports (macOS and Linux)
  # ####################################

  @tag :virtual_ports
  test "create a virtual output port" do
    port_name = "My Virtual Output"

    # Port  count
    %{input: initial_num_input_ports} = Midiex.port_count()

    # Connection
    virtual_out_conn = Midiex.create_virtual_output(port_name)
    assert is_struct(virtual_out_conn, Midiex.OutConn), "expected a %Midiex.OutConn{} struct"

    assert virtual_out_conn.name == port_name,
           "expected %Midiex.OutConn{} name to be \"#{port_name}\""

    # Input port count should be +1
    %{input: num_input_ports} = Midiex.port_count()

    assert num_input_ports == initial_num_input_ports + 1,
           "expected the number of input ports to be \"#{initial_num_input_ports + 1}\""

    # Port visible
    input_port = Midiex.ports(~r/#{port_name}/, :input) |> List.first()
    assert is_struct(input_port, Midiex.MidiPort), "expected a %Midiex.MidiPort{} struct"
    assert input_port.name =~ port_name, "expected %Midiex.MidiPort{} name to be \"#{port_name}\""
    assert input_port.direction == :input, "expected %Midiex.MidiPort{} direction to be :input"
  end

  @tag :virtual_ports
  test "create a virtual input port" do
    port_name = "My Virtual Input"

    # Port count
    %{output: initial_num_output_ports} = Midiex.port_count()

    virtual_in_port = Midiex.create_virtual_input(port_name)

    assert is_struct(virtual_in_port, Midiex.VirtualMidiPort),
           "expected a %Midiex.VirtualMidiPort{} struct"

    assert virtual_in_port.name == port_name,
           "expected %Midiex.VirtualMidiPort{} name to be \"#{port_name}\""

    assert virtual_in_port.direction == :input,
           "expected %Midiex.VirtualMidiPort{} direction to be :input"

    # Subscribe to the port, this will create an %Midiex.MidiPort{direction: :output}
    Midiex.subscribe(virtual_in_port)

    # Port visible
    output_port = wait_for_port(~r/#{port_name}/, :output)
    assert is_struct(output_port, Midiex.MidiPort), "expected a %Midiex.MidiPort{} struct"

    # Give the thread-local MIDI clients 50ms to synchronize port counts
    :timer.sleep(50)

    assert output_port.name =~ port_name,
           "expected %Midiex.MidiPort{} name to be \"#{port_name}\""

    assert output_port.direction == :output, "expected %Midiex.MidiPort{} direction to be :output"

    # Output port count should be +1
    %{output: num_output_ports} = Midiex.port_count()

    assert num_output_ports == initial_num_output_ports + 1,
           "expected the number of output ports to be \"#{initial_num_output_ports + 1}\""

    # Clean up
    Midiex.unsubscribe(virtual_in_port)
  end

  @tag :virtual_ports
  test "sysex and send and recieve MIDI message test" do
    port_name = "SysEx test"
    test_pid = self()

    # Create port
    out_conn = Midiex.create_virtual_output(port_name)

    # Setup listener
    input_port = wait_for_port(~r/#{port_name}/, :input)
    {:ok, pid} = Midiex.Listener.start_link(port: input_port)
    Midiex.Listener.add_handler(pid, fn msg -> send(test_pid, {:sysex_msg, msg.data}) end)

    # Force synchronization with the GenServer and allow the Rust background thread to initialize
    _ = Midiex.Listener.get_state(pid)
    :timer.sleep(50)

    # Create SysEx message, using Roland device id, and send it to the virual output
    roland_device_id = 0x41
    bin_message = <<1, 2, 3, 4>>
    message = Midiex.Message.sysex(roland_device_id, bin_message)
    # sends [240, 65, 1, 2, 3, 4, 247]
    Midiex.send_msg(out_conn, message)

    # Check if message data was received
    assert_receive {:sysex_msg, <<240, 65, 1, 2, 3, 4, 247>>}, 500

    # Clean-up
    Midiex.Listener.unsubscribe(pid, input_port)
    Midiex.close(out_conn)
    GenServer.stop(pid)
  end

  @tag :virtual_ports
  test "send and receive MIDI message over virtual input" do
    port_name = "Virtual Input Message Test"

    virtual_in_port = Midiex.create_virtual_input(port_name)

    # Subscribe to the virtual input port using a listener
    test_pid = self()
    {:ok, listener_pid} = Midiex.Listener.start_link(port: virtual_in_port)

    Midiex.Listener.add_handler(listener_pid, fn msg ->
      send(test_pid, {:virtual_msg, msg.data})
    end)

    # Find the corresponding OS-visible output port
    output_port = wait_for_port(~r/#{port_name}/, :output)
    out_conn = Midiex.open(output_port)

    # Send a message to the virtual input via the output connection
    # sends <<144, 48, 127>>
    message = Midiex.Message.note_on(:C3, 127)
    Midiex.send_msg(out_conn, message)

    # Assert that the listener processes the message and it is a binary!
    assert_receive {:virtual_msg, binary_msg}, 500

    assert binary_msg == <<144, 48, 127>>,
           "expected binary midi message, got #{inspect(binary_msg)}"

    # Clean up
    Midiex.Listener.unsubscribe(listener_pid, virtual_in_port)
    Midiex.close(out_conn)
    GenServer.stop(listener_pid)
  end

  # ####################################
  # Subscription Tracking
  # ####################################

  @tag :virtual_ports
  test "subscribed_ports/0 tracks active subscriptions and unsubscribe/1 clears them" do
    port_name = "Tracking Test Port"
    virtual_in_port = Midiex.create_virtual_input(port_name)

    # Initially tracking list should not contain our port
    assert virtual_in_port not in Midiex.subscribed_ports()

    # Subscribe
    Midiex.subscribe(virtual_in_port)
    assert virtual_in_port in Midiex.subscribed_ports()

    # Unsubscribe
    Midiex.unsubscribe(virtual_in_port)
    assert virtual_in_port not in Midiex.subscribed_ports()
  end

  # ####################################
  # Platform specific tests
  # ####################################

  @tag :windows_only
  test "virtual port functions raise unsupported errors on Windows" do
    assert_raise ErlangError, ~r/not supported on Windows/i, fn ->
      Midiex.create_virtual_input("Win Input")
    end

    assert_raise ErlangError, ~r/not supported on Windows/i, fn ->
      Midiex.create_virtual_output("Win Output")
    end
  end

  @tag :macos_only
  test "notifications and hotplug functions start successfully on macOS" do
    assert Midiex.notifications() == :ok
    assert Midiex.hotplug() == :ok
  end

  @tag :non_macos
  test "notifications and hotplug functions raise unsupported errors on non-macOS platforms" do
    assert_raise ErlangError, ~r/not yet enabled for this platform/i, fn ->
      Midiex.notifications()
    end

    assert_raise ErlangError, ~r/not yet enabled for this platform/i, fn ->
      Midiex.hotplug()
    end
  end

  defp wait_for_port(name, direction, retries \\ 20) do
    case Midiex.ports(name, direction) do
      [port | _] ->
        port

      [] ->
        if retries > 0 do
          :timer.sleep(10)
          wait_for_port(name, direction, retries - 1)
        else
          raise "Timeout waiting for MIDI port #{name} (#{direction})"
        end
    end
  end
end
