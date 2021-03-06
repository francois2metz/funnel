defmodule Funnel.Es do
  @moduledoc """

  Interface to Elasticsearch:

  * create/delete indexes
  * register/unregister queries
  * percolate
  """

  use HTTPotion.Base
  alias Funnel.QuerySearch

  @doc """

  Returns the url used in the current request.

  This is the function used by HTTPotion to make everything works.
  """
  def process_url(url) do
    "#{host}#{url}"
  end

  @doc """

  Returns a list of query_id matched by the Elasticsearch percolation.
  """
  def percolate(index_id, body) do
    percolation = post("/#{namespace(index_id)}/message/_percolate", body)
    {:ok, body} = JSEX.decode percolation.body
    body["matches"] || []
  end

  @doc """

  Register a query against an Elasticsearch index.

  * `index_id` - Index's id
  * `token`    - User's token
  * `query`    - Query in json
  """
  def register(index_id, token, query) do
    register(index_id, token, Funnel.Uuid.generate, query)
  end

  @doc """

  Update a query, or create a query with a specific id.

  * `index_id` - Index's id
  * `token`    - User's token
  * `uuid`     - Query's id
  * `query`    - Query in json
  """
  def register(index_id, token, uuid, query) do
    id = "#{token}-#{uuid}"
    percolation = put("/_percolator/#{index_id}_#{Mix.env}/#{id}", query)
    {:ok, body} = JSEX.decode(percolation.body)
    {:ok, response} = JSEX.encode([query_id: uuid, index_id: index_id, body: body])
    {percolation.status_code, response}
  end

  @doc """

  Remove all queries from a given index.

  * `index_id` - Index's id
  """
  def unregister(index_id) do
    do_unregister("/_percolator/#{namespace(index_id)}")
  end

  @doc """

  Remove a given query from a given index.

  * `index_id` - Index's id
  * `token`    - User's token
  * `uuid`     - Query's id
  """
  def unregister(index_id, token, id) do
    do_unregister("/_percolator/#{namespace(index_id)}/#{token}-#{id}")
  end

  @doc """

  Returns a list of query for a given token.

  * `token`     - User's token. Mandatory.
  * `query_id` - Query's id. Optional, default to "*".
  * `index_id`  - Index's id. Optional, default to "*".
  * `from`      - Used for pagination. Optional, default to 0.
  * `size`      - Maximum size of returned results. Optional, default to 0.
  """
  def find(token, search_query \\ HashDict.new) do
    post("/_percolator/_search", QuerySearch.query(token, search_query))
      |> QuerySearch.response
  end

  @doc """

  Refresh Elasticsearch indexes.
  """
  def refresh do
    post("/_refresh", "")
  end

  @doc """

  Create an empty index.
  """
  def create do
    put("/#{namespace}", "")
  end

  @doc """

  Create an index with mappings and settings.

  * `body`     - Mappings and settings in json
  """
  def create(body) do
    uuid = Funnel.Uuid.generate
    response = post("/#{namespace(uuid)}", body)
    {:ok, body} = JSEX.decode(response.body)
    {:ok, serialization} = JSEX.encode([index_id: uuid, body: body])
    {response.status_code, serialization}
  end

  @doc """

  Delete an index.
  """
  def destroy(index_id) do
    "/#{namespace(index_id)}"
      |> delete
  end

  defp do_unregister(path) do
    del = delete path
    {del.status_code, del.body}
  end

  def namespace do
    "funnel_#{Mix.env}"
  end

  def namespace(index_id) do
    "#{index_id}_#{Mix.env}"
  end

  defp host do
    case System.get_env("FUNNEL_ES_HOST") do
      nil  -> "http://localhost:9200"
      host -> host
    end
  end
end
