defmodule GenMQTT.Mixfile do
  use Mix.Project

  def project do
    [app: :gen_mqtt,
     version: "0.3.1",
     elixir: "~> 1.2",
     description: description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"]],
     dialyzer: [plt_add_apps: [:kernel, :vmq_commons],
                paths: ["_build/dev/lib/gen_mqtt/ebin", "_build/dev/lib/vmq_commons/ebin"]],
     package: package]
  end

  def description do
    """
    An Elixir behaviour that makes it possible to communicate with a MQTT server
    """
  end

  def package do
    [maintainers: ["Martin Gausby"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/gausby/gen_mqtt",
              "Issues" => "https://github.com/gausby/gen_mqtt/issues"},
     files: ["lib", "README.md", "LICENSE", "mix.exs"]]
  end

  def application do
    []
  end

  defp deps do
    [{:vmq_commons, "1.0.0"},
     {:ex_doc, "~> 0.12", only: :dev},
     {:earmark, "~> 0.2", only: :dev},
     {:gproc, "~> 0.5.0", only: :test},
     {:dialyze, "~> 0.2.1", only: [:dev, :test]}]
  end
end
