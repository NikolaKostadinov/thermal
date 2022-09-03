-module(node).
-export([ start/1, init/1, start/2, init/2 ]).

start(InitTemp) ->
	
	%% start a thermal node with no boundaries  

	spawn(?MODULE, init, [ InitTemp ]).

start(InitTemp, Bound) ->

	%% start a thermal node with boundares
	%% Bound must be: [ { Dir, Pid }, ... ]
	
	spawn(?MODULE, init, [ InitTemp, Bound ]).

init(InitTemp) ->

	%% initate a thermal node process with no boundaries

	io:format("Node ~p started with ~p °K ~n", [ self(), InitTemp ]),
	Bound = { bound, [ { up, none }, { down, none }, { left, none }, { right, none } ] },
	Temp = { temp, InitTemp },
	loop({ Temp, Bound }).

init(InitTemp, Bound) ->

	%% start a thermal node with boundaries
	%% Bound must be: [ { Dir, Pid }, ... ]

	io:format("Node ~p started with ~p °K ~n", [ self(), InitTemp ]),
	Temp = { temp, InitTemp },
	loop({ Temp, { bound, Bound } }).

loop({ { temp, Temp }, { bound, Bound } } = State) ->
	
	%% STATE:
	%%
	%% {
	%% 	{ temp, TEMPERATURE },
	%% 	{ bound, [
	%% 		{ up, PID },
	%% 		{ down, PID },
	%% 		{ left, PID },
	%% 		{ right, PID } 
	%% 	] },
	%% 	{ cache, CACHE }
	%% }

	UpTuple = lists:keyfind(up, 1, Bound),
	if not UpTuple -> Up = none; true -> { up, Up } = UpTuple end,

	DownTuple = lists:keyfind(down, 1, Bound),
	if not DownTuple -> Down = none; true -> { down, Down } = DownTuple end,

	LeftTuple = lists:keyfind(left, 1, Bound),
	if not LeftTuple -> Left = none; true -> { left, Left } = LeftTuple end,

	RightTuple = lists:keyfind(right, 1, Bound),
	if not RightTuple -> Right = none; true -> { right, Right } = RightTuple end,

	receive

		{ dev, log } ->

			io:format("====================~n"),
			io:format("thermal node PID: ~p~n", [ self() ]),
			io:format("temperature: ~p °K~n", [ Temp ]),
			io:format("upper node: ~p~n", [ Up ]),
			io:format("lower node: ~p~n", [ Down ]),
			io:format("left node: ~p~n", [ Left ]),
			io:format("right node: ~p~n", [ Right ]),
			io:format("====================~n"),

			NewState = State;
		
		{ dev, vlog } ->

			%%       ( )
			%%        |
			%% ( ) - ( ) - ( )
			%%        |
			%%       ( )

			if Up =/= none -> Up ! { self(), temp }, receive { Up, { temp, UT } } -> UpTemp = UT end; true -> UpTemp = '' end,
			if Down =/= none -> Down ! { self(), temp }, receive { Down, { temp, DT } } -> DownTemp = DT end; true -> DownTemp = '' end,
			if Left =/= none -> Left ! { self(), temp }, receive { Left, { temp, LT } } -> LeftTemp = LT end; true -> LeftTemp = '' end,
			if Right =/= none -> Right ! { self(), temp }, receive { Right, { temp, RT } } -> RightTemp = RT end; true -> RightTemp = '' end,

			io:format("      (~p°K)~n         |~n", [ UpTemp ]),
			io:format("(~p°K) - (~p°K) - (~p°K)~n", [ LeftTemp, Temp, RightTemp ]),
			io:format("         |~n      (~p°K)~n", [ DownTemp ]),

			NewState = State;

		{ Client, temp } when is_pid(Client) ->

			Client ! { self(), { temp, Temp } },

			NewState = State;

		Any ->

			io:format("~p is undefined for ~p~n", [ Any, self() ]),

			NewState = State

	end,

	loop(NewState).
