defmodule GenMQTT do
  @moduledoc """
  A behaviour module for implementing MMQT client processes.

  ## Example

  This example assumes an MQTT server running on the localhost on
  port 1883.

      defmodule TemperatureLogger do
        use GenMQTT

        def start_link do
          GenMQTT.start_link(__MODULE__, nil)
        end

        def on_connect(state) do
          :ok = GenMQTT.subscribe(self, "room/+/temp", 0)
          {:ok, state}
        end

        def on_publish(["room", location, "temp"], message, state) do
          IO.puts "It is #\{message\} degrees in #\{location\}"
          {:ok, state}
        end
      end

  This will log to the console every time a sensor post a temperature
  to the broker.

  ## Callbacks

  GenMQTT defines 12 callbacs, all of them are automatically defined
  when you use GenMQTT in your module, letting you define the callbacks
  you want to customize. Six of the callbacks are similar to the ones
  you know from GenServer, and the GenServer documentation should be
  consulted for info on these. They are: `init/1`, `handle_call/3`,
  `handle_cast/2`, `handle_info/2`, `terminate/2`, and `code_change/3`.

  The remaining six are specific to GenMQTT and deals with various
  events in a MQTT life cycle:

    * `on_connect/1` is run when the client connect or reconnect with
      the broker.

    * `on_connect_error/2` is triggered if the connection fails for
      whatever reason.

    * `on_disconnect/1` is run when the client disconnect from the MQTT
      broker.

    * `on_subscribe/2` run when the client subscribes to a topic.

    * `on_unsubscribe/2` run when the client stop subscribing to a
      topic.

    * `on_publish/3` triggered everytime something is published to the
      broker.

  All callbacks are optional. A macro will define a default function for
  undefined callbacks, so you only need to implement `on_publish/3` if
  that is what you need.

  ## Name Registration

  A GenMQTT is bound to the same name registration rules as GenServers.
  Read more about it in the Elixir GenServer docs.
  """

  # these follows the gen_server specs ---------------------------------
  @doc """
  Invoked when the server is started. `start_link/3` and `start/3` will
  block until it returns. `state` is the second term passed into either
  of the two start functions.

  When this function returns `{:ok, state}` it will enter its loop and
  will start receiving messages from the broker, or send messages to it
  as soon as it has entered the connected state.

  Returning `{:stop, reason}` will cause the start function to return
  `{:error, reason}`, and the process will exit with `reason` without
  entering its loop or calling `terminate/2`.
  """
  @callback init(state) ::
    {:ok, state} |
    {:ok, state, timeout | :hibernate} |
    :ignore |
    {:stop, reason :: any} when state: any

  @type from :: {pid, tag :: term}
  @callback handle_call(request :: term, from, state) ::
    {:reply, reply, new_state} |
    {:reply, reply, new_state, timeout | :hibernate} |
    {:noreply, new_state} |
    {:noreply, new_state, timeout | :hibernate} |
    {:stop, reason, reply, new_state} |
    {:stop, reason, new_state} when reply: term, state: term, new_state: term, reason: term

  @callback handle_cast(request :: term, state) ::
    {:noreply, new_state} |
    {:noreply, new_state, timeout | :hibernate} |
    {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback handle_info(msg :: :timeout | term, state) ::
    {:noreply, new_state} |
    {:noreply, new_state, timeout | :hibernate} |
    {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback terminate(reason, state) ::
    term when state: term, reason: :normal | :shutdown | {:shutdown, term} | term

  @callback code_change(old_vsn, state :: term, extra :: term) ::
    {:ok, new_state :: term} |
    {:error, reason :: term} when old_vsn: term | {:down, term}

  # gen_emqtt ----------------------------------------------------------
  @type topic :: [binary] | binary
  @type qos :: 0 | 1 | 2

  @doc """
  Triggered when the client successfully establish a connection to the
  broker. It will get run again if the client should disconnect from
  the broker, i.e. it temporarily becomes unavailable for whatever
  reason, if some numeral value has been set to the start option
  `reconnect_timeout`.

  ## Examples

  Subscribe to a topic as soon as a connection has been made to the
  broker:

      def on_connect(state) do
        :ok = GenMQTT.subscribe(self, "room/living-room/temp", 0)
        {:ok, state}
      end
  """
  @callback on_connect(state) ::
    {:ok, state} when state: term

  @doc """
  Callback triggered if there was some problem while connecting to the
  broker. The `reason` is given as the first argument as an atom, making
  it possible to pattern match and react. The second argument is the
  process state.
  """
  @callback on_connect_error(reason, state) ::
    {:ok, state} when [state: term,
                       reason: :server_not_found |
                               :server_not_available |
                               :wrong_protocol_version |
                               :invalid_id |
                               :invalid_credentials |
                               :not_authorized]

  @doc """
  Callback triggered when the client disconnects from the broker for
  whatever reason.
  """
  @callback on_disconnect(state) ::
    {:ok, state} when state: term

  @doc """
  Callback triggered when the client successfully subscribe to one or
  more topics.

  The subscriptions are given in tuples containing the topic name and
  its quality of service.
  """
  @callback on_subscribe([{topic, qos}], state) ::
    {:ok, state} when state: term

  @doc """
  Callback triggered when the client successfully unsubscribe from one
  or more subscriptions. It will receive the no longer subscribed
  subscriptions as a list of binaries as the first argument, and the
  process state as the second.
  """
  @callback on_unsubscribe(topic, state) ::
    {:ok, state} when state: term

  @doc """
  Callback triggered when a message has been published to a topic the
  client subscribe to.

  ## Examples

  The following will print the messages sent to the topic `room/+/temp`.

      def on_publish(["room", room, "temp"], temperature, state) do
        IO.puts "It is #\{temperature\} degrees in #\{room\}""
        {:ok, state}
      end
  """
  @callback on_publish(topic, payload :: binary, state) ::
    {:ok, state} when state: term

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour :gen_emqtt

      @doc false
      def init(state) do
        {:ok, state}
      end

      @doc false
      def on_connect(state) do
        {:ok, state}
      end

      @doc false
      def on_connect_error(reason, state) do
        {:ok, state}
      end

      @doc false
      def on_disconnect(state) do
        {:ok, state}
      end

      @doc false
      def on_subscribe([{_topic, _qos}]=subscription, state) do
        {:ok, state}
      end

      @doc false
      def on_unsubscribe([_topic], state) do
        {:ok, state}
      end

      @doc false
      def on_publish(_topic, _msg, state) do
        {:ok, state}
      end

      @doc false
      def handle_call(msg, _from, state) do
        # We do this to trick Dialyzer to not complain about non-local returns.
        reason = {:bad_call, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def handle_cast(msg, state) do
        # We do this to trick Dialyzer to not complain about non-local returns.
        reason = {:bad_cast, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end

      @doc false
      def handle_info(_msg, state) do
        {:noreply, state}
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      @doc false
      def code_change(_old_version, state, _extra) do
        {:ok, state}
      end

      defoverridable [
        init: 1,

        on_connect: 1, on_connect_error: 2, on_disconnect: 1,
        on_subscribe: 2, on_unsubscribe: 2,
        on_publish: 3,

        handle_call: 3, handle_cast: 2, handle_info: 2,
        terminate: 2, code_change: 3
      ]
    end
  end

  @typedoc "Return values of `start*` functions"
  @type on_start ::
    {:ok, pid} |
    :ignore |
    {:error, {:already_started, pid} | term}

  @typedoc "Debug options supported by the `start*` functions"
  @type debug :: [:trace | :log | :statistics | {:log_to_file, Path.t}]

  @typedoc "The GenMQTT process name"
  @type name :: atom | {:global, term} | {:via, module, term}

  @typedoc "Option values used by the `start*` functions"
  @type option :: {:debug, debug} |
                  {:name, name} |
                  {:timeout, timeout} |
                  {:spawn_opt, Process.spawn_opt} |
                  {:host, :inet.ip_address() | binary} |
                  {:port, :inet.port_number()} |
                  {:username, username :: binary | :undefined} |
                  {:password, password :: binary | :undefined} |
                  {:client, client_id :: binary} |
                  {:clean_session, boolean} |
                  {:last_will_topic, topic :: char_list | binary | :undefined} |
                  {:last_will_msg, payload :: char_list | binary | :undefined} |
                  {:last_will_qos, qos} |
                  {:reconnect_timeout, pos_integer | :undefined} |
                  {:keepalive_interval, pos_integer} |
                  {:retry_interval, pos_integer} |
                  {:proto_version, version :: pos_integer} |
                  {:transport, :gen_tcp.socket() | :ssl.socket()}

  @type options :: [option]

  @doc """
  Start a linked connection to a MQTT broker
  """
  @spec start_link(module, any, options) :: on_start
  def start_link(module, args, options \\ []) when is_atom(module) and is_list(options) do
    options = normalize_options(options)
    case Keyword.pop(options, :name) do
      {nil, opts} ->
        :gen_emqtt.start_link(module, args, opts)
      {name, opts} when is_atom(name) ->
        :gen_emqtt.start_link({:local, name}, module, args, opts)
      {other, opts} when is_tuple(other) ->
        :gen_emqtt.start_link(other, module, args, opts)
    end
  end

  @doc """
  Start an unlinked connection to a MQTT broker
  """
  @spec start(module, any, options) :: on_start
  def start(module, args, options \\ []) when is_atom(module) and is_list(options) do
    options = normalize_options(options)
    case Keyword.pop(options, :name) do
      {nil, opts} ->
        :gen_emqtt.start(module, args, opts)
      {name, opts} when is_atom(name) ->
        :gen_emqtt.start({:local, name}, module, args, opts)
      {other, opts} when is_tuple(other) ->
        :gen_emqtt.start(other, module, args, opts)
    end
  end

  @cast_to_char_list [:host, :client, :last_will_topic, :last_will_msg]
  defp normalize_options(opts) do
    Enum.map(opts, fn
      {key, val} when is_binary(val) and key in @cast_to_char_list ->
        {key, String.to_char_list(val)}

      option ->
        option
    end)
  end

  @doc """
  Subscribe to one or multiple topics given a list of tuples containing
  the topic name and its quality of service `[{"topic", 0}, ..]`
  """
  @spec subscribe(pid, [{topic :: binary, qos}]) :: :ok
  defdelegate subscribe(pid, topics), to: :gen_emqtt

  @doc """
  Subscribe to `topic` with quality of service set to `qos`
  """
  @spec subscribe(pid, topic, qos) :: :ok
  defdelegate subscribe(pid, topic, qos), to: :gen_emqtt

  @doc """
  Unsubscribe from one or more `topic`
  """
  @spec unsubscribe(pid, topic) :: :ok
  defdelegate unsubscribe(pid, topic), to: :gen_emqtt

  @doc """
  Publish `payload` to `topic` with quality of service set to `qos`
  """
  @spec publish(pid, topic, payload :: binary, qos) :: :ok
  def publish(pid, topic, payload, qos) when is_list(topic) do
    :gen_emqtt.publish(pid, topic, payload, qos)
  end
  def publish(pid, topic, payload, qos) when is_binary(topic) do
    publish(pid, [topic], payload, qos)
  end

  @doc """
  Make a call to the underlying state machine
  """
  @spec call(pid, request :: term) :: term
  defdelegate call(pid, request), to: :gen_emqtt

  @doc """
  Make a cast to the underlying state machine
  """
  @spec cast(pid, request :: term) :: :ok
  defdelegate cast(pid, request), to: :gen_emqtt
end
