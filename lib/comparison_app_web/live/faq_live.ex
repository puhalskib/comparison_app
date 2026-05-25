defmodule ComparisonAppWeb.FaqLive do
  use ComparisonAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "FAQ")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6 max-w-2xl">
        <div>
          <h1 class="text-2xl font-bold">FAQ</h1>
          <p class="text-base-content/70 mt-1">
            How comparisons work and how ratings are calculated.
          </p>
        </div>

        <div class="space-y-2">
          <.faq_item
            id="ratings"
            question="How do votes update ratings?"
            open
          >
            <p>
              Each comparison updates streamer ratings using
              <a
                href="https://en.wikipedia.org/wiki/Glicko_rating_system"
                target="_blank"
                rel="noopener noreferrer"
                class="link link-primary"
              >Glicko-2</a>, which tracks a rating, a rating deviation (RD), and volatility.
              More likable votes treat the matchup as a win or loss; “don’t know” votes may skip rating updates or only update one side, depending on your choice.
            </p>
            <p class="mt-3">
              Ratings on the leaderboard reflect the top 100 active streamers. The
              <.link navigate={~p"/ratings"} class="link link-primary">Ratings</.link>
              page shows history over time and can be filtered by period.
            </p>
          </.faq_item>

          <.faq_item id="outcomes" question="What does each vote option do?">
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Choice</th>
                    <th>Effect</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>More likable (left or right)</td>
                    <td>Both streamers updated; winner gets a win, loser a loss</td>
                  </tr>
                  <tr>
                    <td>Don't know left</td>
                    <td>Only the right streamer's rating is updated</td>
                  </tr>
                  <tr>
                    <td>Don't know right</td>
                    <td>Only the left streamer's rating is updated</td>
                  </tr>
                  <tr>
                    <td>Don't know both</td>
                    <td>Comparison is logged; neither rating changes</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </.faq_item>

          <.faq_item id="unknown" question="Why did a streamer stop appearing?">
            <p>
              If you vote that you don't know a streamer, that streamer is hidden from your comparisons for 24 hours.
              This is tracked with a hashed IP address, not stored in plain text.
            </p>
          </.faq_item>

          <.faq_item id="pairing" question="How are matchups chosen?">
            <p>
              Pairs are drawn from the top 100 active streamers, with a mix of rating-aware pairing and random matchups.
              You won't see the same pair twice in one session, and streamers you've marked as unknown are temporarily excluded.
            </p>
          </.faq_item>
        </div>

        <p>
          <.link navigate={~p"/"} class="btn btn-ghost btn-sm">Back to compare</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :question, :string, required: true
  attr :open, :boolean, default: false
  slot :inner_block, required: true

  defp faq_item(assigns) do
    ~H"""
    <div class="collapse collapse-arrow bg-base-200">
      <input type="checkbox" checked={@open} />
      <div class="collapse-title font-medium">{@question}</div>
      <div class="collapse-content text-sm text-base-content/80">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
