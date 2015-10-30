defmodule PKBoss do
  @remote_auth_keys_path "/remote/path/to/auth_keys/file"
  #@local_auth_keys_dir "/local/path/to/pk_boss/auth_keys/dir"
  @local_auth_keys_dir "/auth_keys/"
  @remote_user "root"
  @instructions "To add key: elixir pk_boss.exs --add \"auth_key\"\nTo add key in particular servers: elixir pk_boss.exs --add \"auth_key\" --servers \"ip.address.1, ip.address.2\"\nTo remove key: elixir pk_boss.exs --remove \"auth_key\"\nTo remove key in particular servers: elixir pk_boss.exs --remove \"auth_key\" --servers \"ip.address.1, ip.address.2\"\nTo deploy all auth key files: elixir pk_boss.exs --deploy-all"

  def main do
    {options, values, _} = OptionParser.parse(System.argv, strict: [deploy_all: :boolean, remove: :boolean, add: :boolean, servers: :boolean, verbose: :boolean])
    
    current_path = System.cmd("pwd", [])
                   |> elem(0) 
                   |> String.strip
    path         = "#{current_path}#{@local_auth_keys_dir}"
    files_list = System.cmd("ls", [path]) |> elem(0) |> String.split("\n")
    
    case {options, values} do
      {[], ["h"]} -> IO.puts @instructions
      {[deploy_all: true], []} -> deploy_all(files_list, path)
      {[add: true], [ssh_key]} -> add_user_key(ssh_key, files_list, path)
      {[add: true, servers: true], [ssh_key, servers]} -> add_user_key(ssh_key, parse_servers(servers), path)
      {[remove: true], [ssh_key]} -> remove_user_key(ssh_key, files_list, path)
      {[remove: true, servers: true], [ssh_key, servers]} -> remove_user_key(ssh_key, parse_servers(servers), path)
      {[], _} -> IO.puts "Unrecognized input.\n#{@instructions}"
    end

  end

  def parse_servers(servers) do
    servers |> String.split(",") |> Enum.map( &(String.strip(&1)))
  end

  def empty?(""), do: true
  def empty?(x) when is_binary(x), do: false

  def contains?([], _), do: false
  def contains?([x | _], x), do: true
  def contains?([_head | tail], x), do: contains?(tail, x)
  
  def read_keys(ip, path) do
    {:ok, content} = File.read("#{path}/#{ip}")
    filtered_keys = (String.split(content, "\n") |> Enum.reject(&empty?/1))
    {ip, filtered_keys}
  end

  def deploy_all(files_list, path) do
    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&scp_to_server(&1, path))
  end

  # This is to prepend a key into the authorized_keys file if the key doesn't exist inside the file yet
  def add_user_key(ssh_key, files_list, path) do
    log(files_list, path, ssh_key, :add)

    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&read_keys(&1, path))
    |> Enum.reject(&contains?(elem(&1,1), ssh_key))
    |> Enum.map(&prepend_key(&1, ssh_key, path))
    |> Enum.map(&scp_to_server(&1, path))
  end

  # This is to log out into console whether the server already contain key or clear of key
  def log(files_list, path, ssh_key, action) do
    servers_keys = files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&read_keys(&1, path))
  
    IO.puts @verbose
    
    case {action} do
      {:add} -> 
        servers_keys
        |> Enum.filter(&contains?(elem(&1,1), ssh_key))
        |> Enum.map(&(IO.puts "#{elem(&1,0)} already contains the key #{ssh_key}"))
      {:remove} ->
        servers_keys
        |> Enum.reject(&contains?(elem(&1,1), ssh_key))
        |> Enum.map(&(IO.puts "#{elem(&1,0)} already clear of the key #{ssh_key}"))
    end
  end

  # This prepend ssh_key inside the specified authorized_keys file
  def prepend_key({file_path, _keys}, key, path) do
    {:ok, content} = File.read "#{path}/#{file_path}"
    new_content = "#{key}\n" <> content
    {:ok, file} = File.open "#{path}/#{file_path}", [:write]
    IO.binwrite file, new_content
    File.close file
    IO.puts "Successfully add key #{key} into #{file_path}"
    file_path
  end

  # This is to remove a key in the authorized_keys file if the key does exist inside the file
  def remove_user_key(ssh_key, files_list, path) do
    log(files_list, path, ssh_key, :remove)

    files_list
    |> Enum.reject(&empty?(&1))
    |> Enum.map(&read_keys(&1, path))
    |> Enum.filter(&contains?(elem(&1,1), ssh_key))
    |> Enum.map(&remove_key(&1, ssh_key, path))
    |> Enum.map(&scp_to_server(&1, path))
  end

  # This remove ssh_key inside the specified authorized_keys file
  def remove_key({file_path, _keys}, key, path) do
    {:ok, content} = File.read "#{path}/#{file_path}"

    new_content = String.split(content, "\n") 
                  |> Enum.filter(&(&1 != key)) 
                  |> Enum.join("\n")
    {:ok, file} = File.open "#{path}/#{file_path}", [:write]
    IO.binwrite file, new_content
    File.close file
    IO.puts "Successfully remove key #{key} from #{file_path}"
    file_path
  end

  def scp_to_server(file, path) do
    {_response, code} = System.cmd("scp", ["#{path}/#{file}", "{@remote_user}@#{file}:#{@remote_auth_keys_path}"])
    case code do
      0 -> IO.puts "Success"
      _ -> IO.puts "FAILURE! couldn't scp file: #{file}"
    end
  end

end

PKBoss.main


## TODO:
# add verbosity
# get path based on absolute path to files




