defmodule AppWeb.ItemController do
  use AppWeb, :controller

  alias App.Ctx
  alias App.Ctx.Item

  def index(conn, _params) do
    items = Ctx.list_items()
    render(conn, "index.html", items: items)
  end

  def api_index(conn, _params) do
    items = Ctx.list_items()
    render(conn, "index.json", items: items)
  end

  def new(conn, _params) do
    changeset = Ctx.change_item(%Item{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case Ctx.create_item(item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    item = Ctx.get_item!(id)
    render(conn, "show.html", item: item)
  end

  def edit(conn, %{"id" => id}) do
    item = Ctx.get_item!(id)
    changeset = Ctx.change_item(item)
    render(conn, "edit.html", item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Ctx.get_item!(id)

    case Ctx.update_item(item, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item updated successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Ctx.get_item!(id)
    {:ok, _item} = Ctx.delete_item(item)

    conn
    |> put_flash(:info, "Item deleted successfully.")
    |> redirect(to: Routes.item_path(conn, :index))
  end
end
