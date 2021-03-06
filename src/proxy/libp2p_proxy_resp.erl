%%%-------------------------------------------------------------------
%% @doc
%% == Libp2p2 Proxy Resp ==
%% Libp2p2 Proxy Resp API
%% @end
%%%-------------------------------------------------------------------
-module(libp2p_proxy_resp).

-export([
    create/1
    ,create/2
    ,success/1
    ,multiaddr/1
]).

-include("pb/libp2p_proxy_pb.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-type proxy_resp() :: #libp2p_proxy_resp_pb{}.

-export_type([proxy_resp/0]).

%%--------------------------------------------------------------------
%% @doc
%% Create an proxy respuest
%% @end
%%--------------------------------------------------------------------
-spec create(boolean()) -> proxy_resp().
create(Success) ->
    #libp2p_proxy_resp_pb{success=Success}.

%%--------------------------------------------------------------------
%% @doc
%% Create an proxy respuest
%% @end
%%--------------------------------------------------------------------
-spec create('true', string()) -> proxy_resp().
create(Success=true, MultiAddr) ->
    #libp2p_proxy_resp_pb{success=Success, multiaddr=MultiAddr}.

%%--------------------------------------------------------------------
%% @doc
%% Getter
%% @end
%%--------------------------------------------------------------------
-spec success(proxy_resp()) -> boolean() | 0 | 1.
success(Resp) ->
    Resp#libp2p_proxy_resp_pb.success.

%%--------------------------------------------------------------------
%% @doc
%% Getter
%% @end
%%--------------------------------------------------------------------
-spec multiaddr(proxy_resp()) -> string() | undefined.
multiaddr(Resp) ->
    case Resp#libp2p_proxy_resp_pb.multiaddr of
        undefined -> undefined;
        Bin when is_binary(Bin) -> binary_to_list(Bin);
        List -> lists:flatten(List)
    end.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

%% ------------------------------------------------------------------
%% EUNIT Tests
%% ------------------------------------------------------------------
-ifdef(TEST).

create_test() ->
    ?assertEqual(#libp2p_proxy_resp_pb{success=true}, create(true)).

get_test() ->
    Resp = create(true),
    ?assertEqual(true, success(Resp)).

-endif.
