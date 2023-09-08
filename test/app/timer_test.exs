defmodule App.TimerTest do
  use App.DataCase
  alias App.{Item, Timer}

  describe "timers" do
    @valid_item_attrs %{text: "some text", person_id: 1}

    test "Timer.start/1 returns timer that has been started" do
      {:ok, item} = Item.create_item(@valid_item_attrs)
      assert Item.get_item!(item.id).text == item.text

      started = NaiveDateTime.utc_now()

      {:ok, timer} =
        Timer.start(%{item_id: item.id, person_id: 1, start: started})

      assert NaiveDateTime.diff(timer.start, started) == 0
    end

    test "Timer.stop/1 stops the timer that had been started" do
      {:ok, item} = Item.create_item(@valid_item_attrs)
      assert Item.get_item!(item.id).text == item.text

      {:ok, started} =
        NaiveDateTime.new(Date.utc_today(), Time.add(Time.utc_now(), -1))

      {:ok, timer} =
        Timer.start(%{item_id: item.id, person_id: 1, start: started})

      assert NaiveDateTime.diff(timer.start, started) == 0

      ended = NaiveDateTime.utc_now()
      {:ok, timer} = Timer.stop(%{id: timer.id, stop: ended})
      assert NaiveDateTime.diff(timer.stop, timer.start) == 1
    end

    test "stop_timer_for_item_id(item_id) should stop the active timer (happy path)" do
      {:ok, item} = Item.create_item(@valid_item_attrs)

      {:ok, seven_seconds_ago} =
        NaiveDateTime.new(Date.utc_today(), Time.add(Time.utc_now(), -7))

      # Start the timer 7 seconds ago:
      {:ok, timer} =
        Timer.start(%{item_id: item.id, person_id: 1, start: seven_seconds_ago})

      #  stop the timer based on it's item_id
      Timer.stop_timer_for_item_id(item.id)

      stopped_timer = Timer.get_timer!(timer.id)
      assert NaiveDateTime.diff(stopped_timer.start, seven_seconds_ago) == 0
      assert NaiveDateTime.diff(stopped_timer.stop, stopped_timer.start) == 7
    end

    test "stop_timer_for_item_id(item_id) should not explode if there is no timer (unhappy path)" do
      # random int
      zero_item_id = 0
      Timer.stop_timer_for_item_id(zero_item_id)
      assert "Don't stop believing!"
    end

    test "stop_timer_for_item_id(item_id) should not melt down if item_id is nil (sad path)" do
      # random int
      nil_item_id = nil
      Timer.stop_timer_for_item_id(nil_item_id)
      assert "Keep on truckin'"
    end
  end

  # defp create_person(_) do
  #   person = Person.create_person(%{"person_id" => 1, "name" => "guest"})
  #   %{person: person}
  # end
end
