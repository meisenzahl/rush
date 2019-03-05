public class Pomodoro.Pomodoro : Object {
    public DateTime start_date { get; set; }
    public DateTime? end_date { get; set; }
    public State state { get; set; }
    public bool completed {
        get { return end_date != null; }
    }

    public Pomodoro (State pomodoro_state) {
        start_date = new DateTime.now_utc ();
        state = pomodoro_state;
    }

    public void end () {
        end_date = new DateTime.now_utc ();
    }
}
