# Test exclusions based on the operating system:
# On Windows: Skips `:virtual_ports` and `:macos_only`, but executes standard tests and `:windows_only` assertions.
# On Linux: Skips `:windows_only` and `:macos_only`, but executes standard tests and `:virtual_ports`.
# On macOS: Skips `:windows_only` and `:non_macos`, executing standard, virtual port, and `:macos_only` tests.

exclusions =
  case :os.type() do
    {:win32, :nt} ->
      [:virtual_ports, :macos_only]

    {:unix, :darwin} ->
      [:windows_only, :non_macos]

    _ ->
      # Linux and other UNIX systems
      # If the ALSA sequencer is not available (e.g. in Colima/Docker containers without seq), exclude virtual ports
      if File.exists?("/dev/snd/seq") do
        [:windows_only, :macos_only]
      else
        [:windows_only, :macos_only, :virtual_ports]
      end
  end

ExUnit.start(exclude: exclusions)
