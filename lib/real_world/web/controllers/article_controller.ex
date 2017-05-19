defmodule RealWorld.Web.ArticleController do
  use RealWorld.Web, :controller
  use Guardian.Phoenix.Controller

  alias RealWorld.Blog
  alias RealWorld.Blog.Article

  action_fallback RealWorld.Web.FallbackController

  plug Guardian.Plug.EnsureAuthenticated, %{handler: RealWorld.Web.SessionController} when action in [:create]

  def index(conn, _params, _user, _full_claims) do
    articles = Blog.list_articles()
               |> RealWorld.Repo.preload(:author)
    render(conn, "index.json", articles: articles)
  end

  def create(conn, %{"article" => article_params}, user, _full_claims) do
    with %Article{} = article <- Blog.create_article(article_params |> Map.merge(%{"user_id" => user.id})) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", article_path(conn, :show, article))
      |> render("show.json", article: article)
    end
  end

  def show(conn, %{"id" => slug}, _user, _full_claims) do
    article = Blog.get_article_by_slug!(slug)
    render(conn, "show.json", article: article)
  end

  def update(conn, %{"id" => id, "article" => article_params}, _user, _full_claims) do
    article = Blog.get_article!(id)

    with {:ok, %Article{} = article} <- Blog.update_article(article, article_params) do
      render(conn, "show.json", article: article)
    end
  end

  def delete(conn, %{"id" => slug}, _user, _full_claims) do
    # {:ok, %Article{}} <-
    Blog.delete_article(slug)
    send_resp(conn, :no_content, "")
  end
end
