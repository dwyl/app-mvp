defmodule AppWeb.AppLiveTest do
  use AppWeb.ConnCase
  alias App.{Item, Person, Timer, Tag}
  import Phoenix.LiveViewTest
  alias Phoenix.Socket.Broadcast

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "done"
    assert render(page_live) =~ "done"
  end

  test "connect and create an item", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert render_submit(view, :create, %{
             text: "Learn Elixir",
             person_id: nil,
             tags: ""
           })
  end

  test "toggle an item", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Learn Elixir", status: 2, person_id: 0})

    {:ok, _item2} =
      Item.create_item(%{text: "Learn Elixir", status: 4, person_id: 0})

    assert item.status == 2

    started = NaiveDateTime.utc_now()
    {:ok, _timer} = Timer.start(%{item_id: item.id, start: started})

    # See: https://github.com/dwyl/useful/issues/17#issuecomment-1186070198
    # assert Useful.typeof(:timer_id) == "atom"
    assert Item.items_with_timers(1) > 0

    {:ok, view, _html} = live(conn, "/?filter_by=all")

    assert render_click(view, :toggle, %{"id" => item.id, "value" => "on"}) =~
             "line-through"

    updated_item = Item.get_item!(item.id)
    assert updated_item.status == 4
  end

  test "(soft) delete an item", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Learn Elixir", person_id: 0, status: 2})

    assert item.status == 2

    {:ok, view, _html} = live(conn, "/")
    assert render_click(view, :delete, %{"id" => item.id}) =~ "done"

    updated_item = Item.get_item!(item.id)
    assert updated_item.status == 6
  end

  test "start a timer", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Get Fancy!", person_id: 0, status: 2})

    assert item.status == 2

    {:ok, view, _html} = live(conn, "/")
    assert render_click(view, :start, %{"id" => item.id})
  end

  test "stop a timer", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Get Fancy!", person_id: 0, status: 2})

    assert item.status == 2
    started = NaiveDateTime.utc_now()
    {:ok, timer} = Timer.start(%{item_id: item.id, start: started})

    {:ok, view, _html} = live(conn, "/")

    assert render_click(view, :stop, %{"id" => item.id, "timerid" => timer.id}) =~
             "done"
  end

  test "handle_info/2 update", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    {:ok, item} =
      Item.create_item(%{text: "Always Learning", person_id: 0, status: 2})

    send(view.pid, %Broadcast{
      event: "update",
      payload: :create
    })

    assert render(view) =~ item.text
  end

  test "edit-item", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Learn Elixir", person_id: 0, status: 2})

    {:ok, view, _html} = live(conn, "/")

    assert render_click(view, "edit-item", %{"id" => Integer.to_string(item.id)}) =~
             "<form phx-submit=\"update-item\" id=\"form-update\""
  end

  test "update an item", %{conn: conn} do
    {:ok, item} =
      Item.create_item(%{text: "Learn Elixir", person_id: 0, status: 2})

    {:ok, view, _html} = live(conn, "/")

    assert render_submit(view, "update-item", %{
             "id" => item.id,
             "text" => "Learn more Elixir",
             "tags" => "Learn, Elixir"
           })

    updated_item = Item.get_item!(item.id)
    assert updated_item.text == "Learn more Elixir"
    assert length(updated_item.tags) == 2
  end

  test "timer_text(start, stop)" do
    timer = %{
      start: ~N[2022-07-17 09:01:42.000000],
      stop: ~N[2022-07-17 13:22:24.000000]
    }

    assert AppWeb.AppLive.timer_text(timer) == "04:20:42"
  end

  test "filter items", %{conn: conn} do
    {:ok, _item} =
      Item.create_item(%{text: "Item to do", person_id: 0, status: 2})

    {:ok, _item_done} =
      Item.create_item(%{text: "Item done", person_id: 0, status: 4})

    {:ok, _item_archived} =
      Item.create_item(%{text: "Item archived", person_id: 0, status: 6})

    {:ok, view, _html} = live(conn, "/?filter_by=all")
    assert render(view) =~ "Item to do"
    assert render(view) =~ "Item done"
    assert render(view) =~ "Item archived"

    {:ok, view, _html} = live(conn, "/?filter_by=active")
    assert render(view) =~ "Item to do"
    refute render(view) =~ "Item done"
    refute render(view) =~ "Item archived"

    {:ok, view, _html} = live(conn, "/?filter_by=done")
    refute render(view) =~ "Item to do"
    assert render(view) =~ "Item done"
    refute render(view) =~ "Item archived"

    {:ok, view, _html} = live(conn, "/?filter_by=archived")
    refute render(view) =~ "Item to do"
    refute render(view) =~ "Item done"
    assert render(view) =~ "Item archived"
  end

  test "filter items by tag name", %{conn: conn} do
    {:ok, _item} =
      Item.create_item_with_tags(%{
        text: "Item1 to do",
        person_id: 0,
        status: 2,
        tags: "tag1, tag2"
      })

    {:ok, _item} =
      Item.create_item_with_tags(%{
        text: "Item2 to do",
        person_id: 0,
        status: 2,
        tags: "tag1, tag3"
      })

    {:ok, view, _html} = live(conn, "/?filter_by=all")
    assert render(view) =~ "Item1 to do"
    assert render(view) =~ "Item2 to do"

    {:ok, view, _html} = live(conn, "/?filter_by=all&filter_by_tag=tag2")
    assert render(view) =~ "Item1 to do"
    refute render(view) =~ "Item2 to do"

    {:ok, view, _html} = live(conn, "/?filter_by=all&filter_by_tag=tag3")
    refute render(view) =~ "Item1 to do"
    assert render(view) =~ "Item2 to do"

    {:ok, view, _html} = live(conn, "/?filter_by=all&filter_by_tag=tag1")
    assert render(view) =~ "Item1 to do"
    assert render(view) =~ "Item2 to do"
  end

  test "get / with valid JWT", %{conn: conn} do
    data = %{
      email: "test@dwyl.com",
      givenName: "Alex",
      picture: "this",
      auth_provider: "GitHub",
      id: 0
    }

    jwt = AuthPlug.Token.generate_jwt!(data)

    {:ok, view, _html} = live(conn, "/?jwt=#{jwt}")
    assert render(view)
  end

  test "get /logout with valid JWT", %{conn: conn} do
    data = %{
      email: "test@dwyl.com",
      givenName: "Alex",
      picture: "this",
      auth_provider: "GitHub",
      sid: 1,
      id: 0
    }

    jwt = AuthPlug.Token.generate_jwt!(data)

    conn =
      conn
      |> put_req_header("authorization", jwt)
      |> get("/logout")

    assert "/" = redirected_to(conn, 302)
  end

  test "test login link redirect to authdemo.fly.dev", %{conn: conn} do
    conn = get(conn, "/login")
    assert redirected_to(conn, 302) =~ "authdemo.fly.dev"
  end

  test "tags_to_string/1" do
    assert AppWeb.AppLive.tags_to_string([
             %Tag{text: "Learn"},
             %Tag{text: "Elixir"}
           ]) == "Learn, Elixir"
  end
end
