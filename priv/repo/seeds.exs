alias ComparisonApp.Repo
alias ComparisonApp.Streamers.Streamer

streamers = [
  %{twitch_id: "19571641", login: "ninja", display_name: "Ninja", profile_image_url: nil},
  %{twitch_id: "26490481", login: "shroud", display_name: "shroud", profile_image_url: nil},
  %{twitch_id: "71092938", login: "xqc", display_name: "xQc", profile_image_url: nil},
  %{twitch_id: "36769016", login: "summit1g", display_name: "summit1g", profile_image_url: nil},
  %{twitch_id: "37708526", login: "timthetatman", display_name: "TimTheTatman", profile_image_url: nil},
  %{twitch_id: "427632467", login: "pokimane", display_name: "Pokimane", profile_image_url: nil},
  %{twitch_id: "156037856", login: "asmongold", display_name: "Asmongold", profile_image_url: nil},
  %{twitch_id: "41137751", login: "lirik", display_name: "LIRIK", profile_image_url: nil},
  %{twitch_id: "31239503", login: "sodapoppin", display_name: "Sodapoppin", profile_image_url: nil},
  %{twitch_id: "100901794", login: "hasanabi", display_name: "HasanAbi", profile_image_url: nil},
  %{twitch_id: "181077473", login: "ludwig", display_name: "Ludwig", profile_image_url: nil},
  %{twitch_id: "63083341", login: "mizkif", display_name: "Mizkif", profile_image_url: nil},
  %{twitch_id: "49031286", login: "tarik", display_name: "tarik", profile_image_url: nil},
  %{twitch_id: "55832852", login: "s1mple", display_name: "s1mple", profile_image_url: nil},
  %{twitch_id: "120057187", login: "aceu", display_name: "aceu", profile_image_url: nil},
  %{twitch_id: "71030207", login: "moistcr1tikal", display_name: "MoistCr1TiKaL", profile_image_url: nil},
  %{twitch_id: "121228706", login: "valkyrae", display_name: "Valkyrae", profile_image_url: nil},
  %{twitch_id: "36190458", login: "scump", display_name: "Scump", profile_image_url: nil},
  %{twitch_id: "46882270", login: "tfue", display_name: "Tfue", profile_image_url: nil},
  %{twitch_id: "22484632", login: "forsen", display_name: "Forsen", profile_image_url: nil}
]

for attrs <- streamers do
  %Streamer{}
  |> Streamer.changeset(attrs)
  |> Repo.insert!(on_conflict: :nothing, conflict_target: :twitch_id)
end
