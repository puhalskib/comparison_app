alias ComparisonApp.Repo
alias ComparisonApp.Streamers
alias ComparisonApp.Streamers.Streamer

target_count = 100

known_streamers = [
  %{twitch_id: "19571641", login: "ninja", display_name: "Ninja"},
  %{twitch_id: "26490481", login: "shroud", display_name: "shroud"},
  %{twitch_id: "71092938", login: "xqc", display_name: "xQc"},
  %{twitch_id: "36769016", login: "summit1g", display_name: "summit1g"},
  %{twitch_id: "37708526", login: "timthetatman", display_name: "TimTheTatman"},
  %{twitch_id: "427632467", login: "pokimane", display_name: "Pokimane"},
  %{twitch_id: "156037856", login: "asmongold", display_name: "Asmongold"},
  %{twitch_id: "41137751", login: "lirik", display_name: "LIRIK"},
  %{twitch_id: "31239503", login: "sodapoppin", display_name: "Sodapoppin"},
  %{twitch_id: "100901794", login: "hasanabi", display_name: "HasanAbi"},
  %{twitch_id: "181077473", login: "ludwig", display_name: "Ludwig"},
  %{twitch_id: "63083341", login: "mizkif", display_name: "Mizkif"},
  %{twitch_id: "49031286", login: "tarik", display_name: "tarik"},
  %{twitch_id: "55832852", login: "s1mple", display_name: "s1mple"},
  %{twitch_id: "120057187", login: "aceu", display_name: "aceu"},
  %{twitch_id: "71030207", login: "moistcr1tikal", display_name: "MoistCr1TiKaL"},
  %{twitch_id: "121228706", login: "valkyrae", display_name: "Valkyrae"},
  %{twitch_id: "36190458", login: "scump", display_name: "Scump"},
  %{twitch_id: "46882270", login: "tfue", display_name: "Tfue"},
  %{twitch_id: "22484632", login: "forsen", display_name: "Forsen"}
]

known_logins = MapSet.new(Enum.map(known_streamers, & &1.login))

extra_logins = [
  "criticalrole",
  "emiru",
  "fanum",
  "jynxzi",
  "ironmouse",
  "caseoh247",
  "kaicenat",
  "trainwreckstv",
  "erobb221",
  "nmplol",
  "cyr",
  "extraemily",
  "quqco",
  "mayahiga",
  "fuslie",
  "disguisedtoast",
  "quarterjade",
  "lilypichu",
  "boxbox",
  "yassuo",
  "doublelift",
  "loltyler1",
  "greekgodx",
  "symfuhny",
  "clix",
  "mongraal",
  "healthygamer_gg",
  "zackrawrr",
  "stableronaldo",
  "yourragegaming",
  "neeko",
  "cdawgva",
  "vei",
  "harukakaribu",
  "shxtou",
  "jokiker",
  "auronplay",
  "ibai",
  "rubius",
  "illojuan",
  "thegrefg",
  "juansguarnizo",
  "alanzoka",
  "gaules",
  "baiano",
  "cellbit",
  "felps",
  "casimito",
  "knekro",
  "mixwell",
  "elspreen",
  "rivers_gg",
  "roier",
  "eslcsgob",
  "blastpremier",
  "rocketleague",
  "riotgames",
  "playoverwatch",
  "callofduty",
  "bungie",
  "maximilian_dood",
  "lacari",
  "myth",
  "drlupo",
  "timmac",
  "hutchmf",
  "paymoneywubby",
  "ster",
  "sips",
  "jerma985",
  "videogamedunkey",
  "northernlion",
  "ray__d",
  "cohhcarnage",
  "itmejp",
  "day9tv",
  "savix",
  "quin69",
  "mathil1",
  "caedrel",
  "agraelus",
  "reckful",
  "nani",
  "grubby",
  "savjz",
  "n0ne",
  "hungrybox",
  "zero",
  "leffen",
  "plup",
  "mang0",
  "armada",
  "westballz",
  "fiction",
  "carmen",
  "simply",
  "filian",
  "buffpup",
  "camila",
  "anny",
  "ironmouse",
  "nyanners"
]

extra_logins =
  extra_logins
  |> Enum.uniq()
  |> Enum.reject(&MapSet.member?(known_logins, &1))

padding_count = max(target_count - length(known_streamers) - length(extra_logins), 0)

padding_logins = for i <- 1..padding_count, do: "seed_broadcaster_#{i}"

all_extra_logins = extra_logins ++ padding_logins

extra_streamers =
  Enum.with_index(all_extra_logins, 1)
  |> Enum.map(fn {login, idx} ->
    %{
      twitch_id: "9#{String.pad_leading(Integer.to_string(idx), 7, "0")}",
      login: login,
      display_name: login |> String.replace("_", " ") |> String.capitalize()
    }
  end)

all_streamers =
  (known_streamers ++ extra_streamers)
  |> Enum.uniq_by(& &1.login)
  |> Enum.take(target_count)

for attrs <- all_streamers do
  attrs =
    attrs
    |> Map.put(:profile_image_url, nil)
    |> Map.put(:active, true)

  %Streamer{}
  |> Streamer.changeset(attrs)
  |> Repo.insert!(
    on_conflict: {:replace, [:login, :display_name, :active, :updated_at]},
    conflict_target: :twitch_id
  )
end

Streamers.prune_active_to_top(target_count)

IO.puts("Seeded #{length(all_streamers)} streamers (#{target_count} active max)")
