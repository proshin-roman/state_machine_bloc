import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_timer_state_machine/ticker.dart';
import 'package:state_machine_bloc/state_machine_bloc.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerStateMachine extends StateMachine<TimerEvent, TimerState> {
  TimerStateMachine({required Ticker ticker})
      : _ticker = ticker,
        super(TimerInitial(_duration)) {
    define<TimerInitial>(
      (b) => b..on<TimerStarted>(_onTimerStarted),
    );

    define<TimerRun>(
      (b) => b
        //Reset Timer
        ..on<TimerReset>(_onReset)

        //Timer running
        ..define<TimerRunInProgress>((b) => b
          ..on<TimerTicked>(_onTicked)
          ..on<TimerPaused>(_onPaused))

        //Timer paused
        ..define<TimerRunPause>((b) => b
          ..on<TimerResumed>(
            _onResumed,
          ))

        //Timer Completed
        ..define<TimerRunComplete>(),
    );
  }

  final Ticker _ticker;
  static const int _duration = 60;

  StreamSubscription<int>? _tickerSubscription;

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  Future<TimerRunInProgress> _onTimerStarted(TimerStarted event, _) async {
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker.tick(ticks: event.duration).listen(
      (duration) {
        try {
          add(TimerTicked(duration: duration));
        } catch (e) {
          print(e);
        }
      },
    );
    return TimerRunInProgress(event.duration);
  }

  Future<TimerRunPause> _onPaused(
      TimerPaused event, TimerRunInProgress state) async {
    _tickerSubscription?.pause();
    return TimerRunPause(state.duration);
  }

  Future<TimerRunInProgress> _onResumed(
      TimerResumed resume, TimerRunPause state) async {
    _tickerSubscription?.resume();
    return TimerRunInProgress(state.duration);
  }

  Future<TimerInitial> _onReset(TimerReset event, TimerRun state) async {
    _tickerSubscription?.cancel();
    return TimerInitial(_duration);
  }

  Future<TimerRun> _onTicked(
      TimerTicked event, TimerRunInProgress state) async {
    return event.duration > 0
        ? TimerRunInProgress(event.duration)
        : TimerRunComplete();
  }
}
