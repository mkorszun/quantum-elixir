defmodule QuantumRuntimeTest do
  @moduledoc false

  use ExUnit.Case

  import ExUnit.CaptureLog

  import Crontab.CronExpression

  defmodule Scheduler do
    @moduledoc false

    use Quantum.Scheduler, otp_app: :quantum_runtime_test
  end

  test "should execute runtime task once" do
    capture_log(fn ->
      {:ok, _pid} = start_supervised(Scheduler)

      task(:task_1)

      assert 1 == task_execution_count(:task_1)
    end)
  end

  test "should execute runtime task once after delay from starting scheduler" do
    capture_log(fn ->
      {:ok, _pid} = start_supervised(Scheduler)

      :timer.sleep(3000)
      task(:task_2)

      assert 1 == task_execution_count(:task_2)
    end)
  end

  defp task_execution_count(name) do
    task_execution_count(name, 0)
  end
  defp task_execution_count(name, count) do
    receive do
      {:ok, ^name} ->
        task_execution_count(name, count + 1)
      after 1_000 ->
        count
    end
  end

  defp task(name) do
    pid = self()
    Scheduler.new_job()
    |> Quantum.Job.set_name(name)
    |> Quantum.Job.set_schedule(~e[* * * * * *]e)
    |> Quantum.Job.set_task(fn ->
      send pid, {:ok, name}
      Scheduler.delete_job(name)
    end)
    |> Scheduler.add_job()
    pid
  end
end
