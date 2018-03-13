-module(libp2p_swarm_sup).

-behaviour(supervisor).

% supervisor
-export([init/1]).
% api
-export([sup/1, name/1, address/1,
         register_server/1, server/1,
         register_peerbook/1, peerbook/1]).

-define(SUP, swarm_sup).
-define(SERVER, swarm_server).
-define(PEERBOOK, swarm_peerbook).
-define(ADDRESS, swarm_address).
-define(NAME, swarm_name).

init([Name]) ->
    inert:start(),
    TID = ets:new(Name, [public, ordered_set, {read_concurrency, true}]),
    ets:insert(TID, {?SUP, self()}),
    ets:insert(TID, {?NAME, Name}),
    % Get or generate our keys
    {PrivKey, PubKey} = libp2p_crypto:swarm_keys(TID),
    ets:insert(TID, {?ADDRESS, libp2p_crypto:pubkey_to_address(PubKey)}),
    SigFun = fun(Bin) -> public_key:sign(Bin, sha256, PrivKey) end,

    SupFlags = {one_for_all, 3, 10},
    ChildSpecs = [
                  {listeners,
                   {libp2p_swarm_listener_sup, start_link, [TID]},
                   permanent,
                   10000,
                   supervisor,
                   [libp2p_swarm_listener_sup]
                  },
                  {sessions,
                   {libp2p_swarm_session_sup, start_link, [TID]},
                   permanent,
                   10000,
                   supervisor,
                   [libp2p_swarm_session_sup]
                  },
                  {transports,
                   {libp2p_swarm_transport_sup, start_link, [TID]},
                   permanent,
                   10000,
                   supervisor,
                   [libp2p_swarm_transport_sup]
                  },
                  {?SERVER,
                   {libp2p_swarm_server, start_link, [TID]},
                   permanent,
                   10000,
                   worker,
                   [libp2p_swarm_server]
                  },
                  {?PEERBOOK,
                   {libp2p_peerbook, start_link, [TID, SigFun]},
                   permanent,
                   10000,
                   worker,
                   [libp2p_peerbook]
                  }
                 ],
    {ok, {SupFlags, ChildSpecs}}.

-spec sup(ets:tab()) -> supervisor:sup_ref().
sup(TID) ->
    ets:lookup_element(TID, ?SUP, 2).

register_server(TID) ->
    ets:insert(TID, {?SERVER, self()}).

-spec server(ets:tab() | supervisor:sup_ref()) -> pid().
server(Sup) when is_pid(Sup) ->
    Children = supervisor:which_children(Sup),
    {?SERVER, Pid, _, _} = lists:keyfind(?SERVER, 1, Children),
    Pid;
server(TID) ->
    ets:lookup_element(TID, ?SERVER, 2).

register_peerbook(TID) ->
    ets:insert(TID, {?PEERBOOK, self()}).

-spec peerbook(ets:tab()) -> pid().
peerbook(TID) ->
    ets:lookup_element(TID, ?PEERBOOK, 2).

-spec address(ets:tab()) -> libp2p_crypto:address().
address(TID) ->
    ets:lookup_element(TID, ?ADDRESS, 2).

-spec name(ets:tab()) -> atom().
name(TID) ->
    ets:lookup_element(TID, ?NAME, 2).