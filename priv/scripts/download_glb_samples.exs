# Download Khronos glTF sample GLB files for EAGL examples and tests.
#
# Usage:
#   mix run priv/scripts/download_glb_samples.exs
#
# Or via Mix alias:
#   mix glb.samples
#
# Files are saved to test/fixtures/samples/ and are gitignored.

defmodule EAGL.GLBSamplesDownloader do
  @base_url "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models"

  @samples [
    {"Box", "Box"},
    {"BoxTextured", "BoxTextured"},
    {"Duck", "Duck"},
    {"BoxAnimated", "BoxAnimated"},
    {"DamagedHelmet", "DamagedHelmet"}
  ]

  def run do
    sample_dir = "test/fixtures/samples"
    File.mkdir_p!(sample_dir)

    IO.puts("Downloading GLB samples to #{sample_dir}/")
    IO.puts("")

    results =
      @samples
      |> Enum.map(fn entry -> download(entry, sample_dir) end)

    {ok_count, fail_count} =
      Enum.reduce(results, {0, 0}, fn
        :ok, {ok, fail} -> {ok + 1, fail}
        {:error, _}, {ok, fail} -> {ok, fail + 1}
      end)

    IO.puts("")
    IO.puts("Done: #{ok_count} downloaded, #{fail_count} failed")
    fail_count == 0
  end

  defp download({name, path_segment}, sample_dir) do
    url = "#{@base_url}/#{path_segment}/glTF-Binary/#{name}.glb"
    local_path = Path.join(sample_dir, "#{name}.glb")

    if File.exists?(local_path) do
      IO.puts("  #{name}.glb - already exists")
      :ok
    else
      case do_download(url, local_path) do
        :ok ->
          IO.puts("  #{name}.glb - downloaded")
          :ok

        {:error, reason} ->
          IO.puts("  #{name}.glb - FAILED: #{reason}")
          {:error, reason}
      end
    end
  end

  defp do_download(url, local_path) do
    try do
      :inets.start()

      case :httpc.request(:get, {String.to_charlist(url), []}, [timeout: 60_000],
             body_format: :binary
           ) do
        {:ok, {{_version, 200, _reason}, _headers, body}} ->
          File.write!(local_path, body)
          :ok

        {:ok, {{_version, status, _reason}, _headers, _body}} ->
          {:error, "HTTP #{status}"}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end

EAGL.GLBSamplesDownloader.run()
