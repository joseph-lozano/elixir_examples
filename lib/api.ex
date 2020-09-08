defmodule Example.API do
  def get() do
    with {:ok, resp} <- HTTPoison.get("https://deckofcardsapi.com/api/deck/new/"),
         {:ok, body} <- Map.fetch(resp, :body),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, decoded}
    else
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
      :error -> {:error, :no_body}
      {:error, %Jason.DecodeError{}} -> {:error, :could_not_decode}
    end
  end
end
