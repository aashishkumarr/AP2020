-module(simplefilter).
-export([try_it/0,oneway/1]).
importance(M, C) ->
  Important = binary:compile_pattern([<<"AP">>, <<"Haskell">>, <<"Erlang">>]),
  case binary:match(M, Important, []) of
    nomatch -> {just, C#{spam => true}};
    _ -> {just, C#{importance => 10000}} end.

importance2(M, C) ->
  {transformed, <<"FOrget it">>}.

oneway(Mail) ->
  {ok, MS} = mailfilter:start(infinite),
  mailfilter:default(MS, importance, {simple, fun importance/2}, #{}),
  mailfilter:default(MS, importance1, {simple, fun importance/2}, #{}),
  mailfilter:default(MS, importance2, {simple, fun importance2/2}, #{}),

  {ok, MR} = mailfilter:add_mail(MS, Mail),
  mailfilter:add_filter(MR, importance3, {simple, fun importance/2}, #{}),

  timer:sleep(2000), % Might not be needed,
                   % but we'll give mailfilter a fighting chance to run the filters
  mailfilter:get_config(MR).

another(Mail) ->
  {ok, MS} = mailfilter:start(infinite),

  {ok, MR} = mailfilter:add_mail(MS, Mail),
  mailfilter:add_filter(MR, "importance", {simple, fun importance/2}, #{}),
  mailfilter:add_filter(MR, ap_r0cks, {simple, fun(<<M:24/binary, _>>) ->
                                                  {transform, M} end}, flap),
  timer:sleep(50), % Might not be needed
  {ok, [{M, Config}]} = mailfilter:stop(MS),
  io:fwrite("Config: ~s~n" , [M]),
  Res = [ Result || {Label, Result} <- Config],
  {M, lists:nth(1, Res)}.

try_it() ->
  Mail = <<"Remember to read AP exam text carefully">>,
  {MS, Res1} = oneway(Mail),
  {_M, Res2} = another(Mail),
  {ok, _} = mailfilter:stop(MS),
  Translate = fun (Result) ->
                  case Result of
                    {done, #{spam := true}} -> "We git spam - nom nom nom";
                    {done, #{importance := N}} when N > 69 -> "IMPORTANT!";
                    {done, _} ->                   "Can wait for tomorrow";
                    inprogress ->                   "Need a new computer!"
                  end end,
  io:fwrite("One way: ~s~nor another: ~s~n" , [Translate(Res1), Translate(Res2)]).