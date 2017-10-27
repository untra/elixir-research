defmodule Aehttpclient.Client do
  @moduledoc """
  Client used for making requests to a node.
  """

  alias Aecore.Structures.Block
  alias Aecore.Peers.Worker, as: Peers

  @spec get_info(term()) :: {:ok, map()} | :error
  def get_info(uri) do
    get(uri <> "/info", :info)
  end

  @spec get_block({term(), term()}) :: {:ok, %Block{}} | :error
  def get_block({uri, hash}) do
    get(uri <> "/block/#{hash}", :block)
  end

  @spec send_block({b :: map(), peers :: map()}) :: :ok | :error
  def send_block({b, peers}) do
    peers = Map.keys(peers)
    for peer <- peers do
      send_to_peers(:post, peer <> "/new_block", b)
    end
  end

  @spec get_peers(term()) :: {:ok, list()}
  def get_peers(uri) do
    get(uri <> "/peers", :peers)
  end

  @spec get_and_add_peers(term()) :: :ok
  def get_and_add_peers(uri) do
    {:ok, peers} = get_peers(uri)
    Enum.each(peers, fn{peer, _} -> Peers.add_peer(peer) end)
  end

  @doc """
  TODO
  """
  defp send_to_peers(:post, uri, data) do
    HTTPoison.post uri, Poison.encode!(data),
      [{"Content-Type", "application/json"}]
  end

  def get(uri, identifier) do
    case(HTTPoison.get(uri)) do
      {:ok, %{body: body, status_code: 200}} ->
        case(identifier) do
          :block ->
            response = Poison.decode!(body, as: %Block{}, keys: :atoms!)
            {:ok, response}
          :info ->
            response = Poison.decode!(body, keys: :atoms!)
            {:ok, response}
          :peers ->
            response = Poison.decode!(body)
            {:ok,response}
        end
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        :error
      {:error, %HTTPoison.Error{}} ->
        :error
    end
  end
end