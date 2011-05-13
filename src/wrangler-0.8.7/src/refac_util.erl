%% Copyright (c) 2010, Huiqing Li, Simon Thompson
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%     %% Redistributions of source code must retain the above copyright
%%       notice, this list of conditions and the following disclaimer.
%%     %% Redistributions in binary form must reproduce the above copyright
%%       notice, this list of conditions and the following disclaimer in the
%%       documentation and/or other materials provided with the distribution.
%%     %% Neither the name of the copyright holders nor the
%%       names of its contributors may be used to endorse or promote products
%%       derived from this software without specific prior written permission.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ''AS IS''
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
%% BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
%% BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
%% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
%% OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
%% ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%% =====================================================================
%% Some utility functions used by the refactorer.
%%
%% Author contact: hl@kent.ac.uk, sjt@kent.ac.uk
%%
%% =====================================================================

%% @copyright 2006-2008 Huiqing Li, Simon Thompson
%%
%% @author Huiqing Li <hl@kent.ac.uk>
%%   [http://www.cs.kent.ac.uk/projects/forse]

%% @version  0.3
%% @end
%%
%% @doc Some  utility functions used by Wranlger.
%% @end
%% ============================================
-module(refac_util).   

-export([ghead/2, glast/2, to_lower/1, to_upper/1,
	 try_evaluation/1, is_var_name/1, is_fun_name/1,
	 is_expr/1, is_pattern/1, is_exported/2, inscope_funs/1,
	 once_tdTU/3, stop_tdTP/3, full_tdTP/3, full_buTP/3,
	 pos_to_fun_name/2, pos_to_fun_def/2, pos_to_var_name/2,
	 pos_to_expr/3, pos_to_expr_list/3,
	 pos_to_expr_or_pat_list/3, expr_to_fun/2, get_range/1,
	 get_toks/1, concat_toks/1, tokenize/3,
	 get_var_exports/1, get_env_vars/1, get_bound_vars/1,
	 get_free_vars/1, get_client_files/2, expand_files/2,
	 get_modules_by_file/1, reset_attrs/1, update_ann/2,
	 parse_annotate_file_1/5, parse_annotate_file/3,
	 parse_annotate_file/4, write_refactored_files/1,
	 write_refactored_files/4, write_refactored_files/3,
	 write_refactored_files_for_preview/2,
	 build_lib_side_effect_tab/1,
	 build_local_side_effect_tab/2, has_side_effect/3,
	 callback_funs/1, auto_imported_bifs/0, file_format/1,
	 rewrite/2, predefined_macros/0, default_incls/0, add_range/2]).

-export([test_framework_used/1]).
-export([analyze_free_vars/1, remove_duplicates/1]).
-export([format_search_paths/1]).
-compile(export_all).
-include("../include/wrangler.hrl").

%% =====================================================================
%% @spec(ghead(Info::string(),List::[any()]) -> any()).
%% @doc Same as erlang:hd/1, except the first argument which is the
%%  error message when the list is empty.
%% @see glast/2

%%-spec(ghead(Info::string(),List::[any()]) -> any()).

ghead(Info, []) -> erlang:error(Info);
ghead(_Info, List) -> hd(List).

%% =====================================================================
%% @spec glast(Info::term(), List::[term()]) -> term()
%% @doc Same as lists:last(L), except the first argument which is the 
%%  error message when the list is empty.
%% @see ghead/2

%%-spec(glast(Info::string(), List::[any()]) -> any()).
glast(Info, []) -> erlang:error(Info);
glast(_Info, List) -> lists:last(List).

%% =====================================================================
%% @spec to_upper(Str::string()) -> string()
%% @doc Convert a string into upper case.
%% @see to_lower/1

%%-spec(to_upper(Str::string()) -> string()).
to_upper(Str) ->
    to_upper(Str, []).

to_upper([C | Cs], Acc) when C >= 97, C =< 122 ->
    to_upper(Cs, [C - (97 - 65) | Acc]);
to_upper([C | Cs], Acc) -> to_upper(Cs, [C | Acc]);
to_upper([], Acc) -> lists:reverse(Acc).


%% =====================================================================
%% @spec to_lower(Str::string()) -> string()
%% @doc Convert a string into lower case.
%% @see to_upper/1

%%-spec(to_lower(Str::string()) -> string()).
to_lower(Str) ->
    to_lower(Str, []).

to_lower([C | Cs], Acc) when C >= 65, C =< 90 ->
    to_lower(Cs, [C + (97 - 65) | Acc]);
to_lower([C | Cs], Acc) -> to_lower(Cs, [C | Acc]);
to_lower([], Acc) -> lists:reverse(Acc).


%%====================================================================================
%% @spec try_evaluation(Expr::syntaxTree())->{value, term()}|{error, string()}
%% @doc Try to evaluate an expression. 

%%-spec (try_evaluation(Expr::syntaxTree())->{value, anyterm()}|{error, string()}).
try_evaluation(Expr) ->
    case catch erl_eval:exprs(Expr, []) of
      {value, V, _} -> {value, V};
      _ -> {error, "Error with evaluation"}
    end.

%% =====================================================================
%% @spec once_tdTU(Function, Tree::syntaxTree(), Others::term())-> {term(), boolean()}
%%       Function = (syntaxTree(), term()) -> {term(), boolean()}
%%
%% @doc Once-topdown type-unifying traversal of the abstract syntax tree with some
%% information collected. This function does a pre-order traversal of the
%% abstract syntax tree, and collects the first node, X say, such that
%% Function(X, Others) returns {term(), true}. Function must has a arity of 2, with 
%% the first parameter by the AST node, and all the other necessary information put 
%% into a tupe as the second parameter.
%%
%% @see full_buTP/2
%% @see stop_tdTP/3 		
%% @see refac_syntax_lib:fold/3.
			 
%%-spec(once_tdTU/3::(fun((syntaxTree(), any()) ->
%%			       {anyterm(), boolean()}), syntaxTree(), anyterm()) ->
%%	     {anyterm(), boolean()}).
once_tdTU(Function, Node, Others) ->
    case Function(Node, Others) of
      {R, true} -> {R, true};
      {_R, false} ->
	  case refac_syntax:subtrees(Node) of
	    [] -> {[], false};
	    Gs ->
		Flattened_Gs = [T || G <- Gs, T <- G],
		case Flattened_Gs of
		  [] -> {[], false};
		  [H | T1] -> until(Function, [H | T1], Others)
		end
	  end
    end.

until(_F, [], _Others) -> {[], false};
until(F, [H | T], Others) ->
    case once_tdTU(F, H, Others) of
      {_R, true} -> {_R, true};
      {_Rq, false} -> until(F, T, Others)
    end.


%% =====================================================================
%% @spec stop_tdTP(Function, Tree::syntaxTree(), Others::[term()])->  syntaxTree()
%%       Function = (syntaxTree(),{term()}) -> {syntaxTree(), boolean()}
%%
%% @doc Stop-topdown type-preserving traversal of the abstract syntax tree.
%% This function does a pre-order traversal of the abstract syntax tree, and
%% modifies certain nodes according to Function. Once a node has been modified, 
%% its subtrees are not going to be traversed.
%% 'Function' must have a arity of two, with the first being the AST node, and 
%% the second being a tuple containing all the other needed info; 'Function' 
%% should returns a tuple containing the possibly modified node and a bool value, 
%% with the bool value indicating whether the node has been modified.
%%
%% @see full_buTP/2
%% @see once_tdTU/3

%%-spec(stop_tdTP/3::(fun((syntaxTree(), anyterm()) ->
%%			       {syntaxTree(), boolean()}), syntaxTree(), anyterm()) ->
%%	     {syntaxTree(), boolean()}).
stop_tdTP(Function, Node, Others) ->
    case Function(Node, Others) of
      {Node1, true} -> {Node1, true};
      {Node1, false} ->
	  case refac_syntax:subtrees(Node1) of
	    [] -> {Node1, false};
	    Gs ->
		  Gs1 = [[stop_tdTP(Function, T, Others) || T <- G] || G <- Gs],
		  Gs2 = [[N || {N, _B} <- G] || G <- Gs1],
		  G = [[B || {_N, B} <- G] || G <- Gs1],
		  Node2 = refac_syntax:make_tree(refac_syntax:type(Node1), Gs2),
		  {rewrite(Node1, Node2), lists:member(true, lists:flatten(G))}
	  end
    end.

%%-spec(full_tdTP/3::(fun((syntaxTree(), anyterm()) ->
%%			       {syntaxTree(), boolean()}), syntaxTree(), anyterm()) ->
%%	     {syntaxTree(), boolean()}).
full_tdTP(Function, Node, Others) ->
    case Function(Node, Others) of
	{Node1, Changed} ->
	    case refac_syntax:subtrees(Node1) of
		[] -> {Node1, Changed};
		Gs ->
		    Gs1 = [[full_tdTP(Function, T, Others) || T <- G] || G <- Gs],
		    Gs2 = [[N || {N, _B} <- G] || G <- Gs1],
		    G = [[B || {_N, B} <- G] || G <- Gs1],
		    Node2 = refac_syntax:make_tree(refac_syntax:type(Node1), Gs2),
		    {rewrite(Node1, Node2), Changed or lists:member(true, lists:flatten(G))}
	    end
    end.


%% =====================================================================
%% @spec full_buTP(Function, Tree::syntaxTree(), {term()})-> syntaxTree()
%%       Function = (syntaxTree(), {term()}) -> syntaxTree()
%%
%% @doc Full bottom_up type-preserving traversal of the abstract syntax tree.
%% This function does a bottom_up traversal of the abstract syntax tree, and 
%% modifies certain nodes according to Function. Different from stop_tdTP, all 
%% the nodes in the abstract syntax tree are traversed by this function. 
%%
%%
%% @see stop_tdTP/2
%% @see once_tdTU/3
%%-spec(full_buTP/3::(fun((syntaxTree(), any()) -> syntaxTree()), syntaxTree(), anyterm())->
%%	     syntaxTree()).       
full_buTP(Fun, Tree, Others) ->
    case refac_syntax:subtrees(Tree) of
      [] -> Fun(Tree, Others);
      Gs ->
	  Gs1 = [[full_buTP(Fun, T, Others) || T <- G] || G <- Gs],
	  Tree1 = refac_syntax:make_tree(refac_syntax:type(Tree), Gs1),
	  Fun(rewrite(Tree, Tree1), Others)
    end.


%% ==========================================================================
%% @spec pos_to_fun_name(Node::syntaxTree(), Pos::{integer(), integer()}) ->
%%                        {ok, {Mod, Fun, Arity, OccurPos, DefPos}} | {error, string()}
%%    Mod = atom()
%%    Fun = atom()
%%    Arity = integer()
%%    OccurPos = {integer(), integer()}
%%    DefPos = {integer(), integer()}
%% @doc Get information about the function name which occurs at the specified
%% position in the code. If successful, the returned information contains: 
%% the module in which the function is defined, the function name, the 
%% function's arity, the occurrence position (same as Pos), and the defining 
%% position of this function.
%%
%% @see pos_to_var_name/2
%% @see pos_to_expr/3
%% @see pos_to_fun_def/2.

%%-spec (pos_to_fun_name(Node::syntaxTree(), Pos::pos()) ->
%%	      {ok, {atom(), atom(), integer(), pos(), pos()}} | {error, string()}).
pos_to_fun_name(Node, Pos) ->
    case once_tdTU(fun pos_to_fun_name_1/2, Node, Pos) of
      {_, false} -> {error, "You have not selected a function name,"
		     "or the function/attribute containing the "
		     "function name selected does not parse!"};
      {R, true} -> {ok, R}
    end.

pos_to_fun_name_1(Node, Pos = {Ln, Col}) ->
    As = refac_syntax:get_ann(Node),
    case lists:keysearch(fun_def, 1, As) of
	{value, {fun_def, {Mod, Fun, Arity, {Ln, Col1}, DefPos}}} when is_atom(Fun)->
	    case (Col1 =< Col) and (Col =< Col1 + length(atom_to_list(Fun)) - 1) of
		true -> {{Mod, Fun, Arity, Pos, DefPos}, true};
		false -> {[], false}
	    end;
	_ -> {[], false}
    end.


%%============================================================================
%% @spec pos_to_fun_def(Node::syntaxTree(), Pos::{integer(), integer()}) 
%%                     -> {ok, syntaxTree()} | {error, string()}
%% @doc Get the AST representation of the function definition in which the 
%% location specified by Pos falls.
%%               
%% @see pos_to_fun_name/2.

%%-spec(pos_to_fun_def(Node::syntaxTree(), Pos::pos()) 
%%      -> {ok, syntaxTree()} | {error, string()}).
pos_to_fun_def(Node, Pos) ->
    case once_tdTU(fun pos_to_fun_def_1/2, Node, Pos) of
      {_, false} -> {error, "You have not selected a function definition, "
		     "or the function definition selected does not parse."};
      {R, true} -> {ok, R}
    end.

pos_to_fun_def_1(Node, Pos) ->
    case refac_syntax:type(Node) of
      function ->
	    {S, E} = get_range(Node),
	    if (S =< Pos) and (Pos =< E) ->
		    {Node, true};
	     true -> {[], false}
	  end;
	_ -> {[], false}
    end.


%% =====================================================================
%% @spec pos_to_var_name(Node::syntaxTree(), Pos::{integer(), integer()})->
%%                      {ok, {VarName,DefPos, Category}} | {error, string()}
%%
%%      VarName = atom()
%%      DefPos = [{integer(), integer()}]
%%      Category = expression | pattern | macro_name
%%
%% @doc Get the variable name that occurs at the position specified by Pos.
%% Apart from the variable name, this function all returns other information 
%% including its defining position and its syntax category information.
%%
%% @see pos_to_fun_name/2
%% @see pos_to_fun_def/2
%% @see pos_to_expr/3

%%-type(category()::expression|pattern|macro_name|application_op|operator).
%%-spec(pos_to_var_name(Node::syntaxTree(), Pos::pos())->
%%                      {ok, {atom(), [pos()], category()}} | {error, string()}).
pos_to_var_name(Node, UsePos) ->
    case once_tdTU(fun pos_to_var_name_1/2, Node, UsePos) of
      {_, false} -> {error, "You have not selected a variable name, "
		     "or the function containing the variable does not parse."};
      {R, true} -> {ok, R}
    end.

pos_to_var_name_1(Node, _Pos = {Ln, Col}) ->
    case refac_syntax:type(Node) of
      variable ->
	  {Ln1, Col1} = refac_syntax:get_pos(Node),
	  case (Ln == Ln1) and (Col1 =< Col) and
		 (Col =< Col1 + length(atom_to_list(refac_syntax:variable_name(Node))) - 1)
	      of
	    true ->
		case lists:keysearch(def, 1, refac_syntax:get_ann(Node)) of
		  {value, {def, DefinePos}} ->
		      lists:keysearch(def, 1, refac_syntax:get_ann(Node)),
		      {value, {category, C}} = lists:keysearch(category, 1, refac_syntax:get_ann(Node)),
		      {{refac_syntax:variable_name(Node), DefinePos, C}, true};
		  false ->
		      {value, {category, C}} = lists:keysearch(category, 1, refac_syntax:get_ann(Node)),
		      {{refac_syntax:variable_name(Node), [?DEFAULT_LOC], C}, true}
		end;
	    false -> {[], false}
	  end;
      _ -> {[], false}
    end.


%% =====================================================================
%% @spec pos_to_expr(Tree::syntaxTree(), Start::Pos, End::Pos) ->
%%                  {ok, syntaxTree()} | {error, string()}
%%
%%       Pos={integer(), integer()}
%% @doc Get the largest, left-most expression enclosed by the start and end locations.
%%
%% @see pos_to_fun_name/2
%% @see pos_to_fun_def/2
%% @see pos_to_var_name/2

%%-spec(pos_to_expr(Tree::syntaxTree(), Start::pos(), End::pos()) ->{ok, syntaxTree()} | {error, string()}).
pos_to_expr(Tree, Start, End) ->
    Es =lists:flatten(pos_to_expr_1(Tree, Start, End)),
    case Es of
	[] -> {error, "You have not selected an expression, "
	       "or the function containing the expression selected does not parse."};
	_ -> {ok, hd(Es)}
    end.

pos_to_expr_1(Tree, Start, End) ->
    {S, E} = get_range(Tree),
    if (S >= Start) and (E =< End) ->
	    case is_expr(Tree) of
		true ->
		    [Tree];
		_ ->
		    Ts = refac_syntax:subtrees(Tree),
		    R0 = [[pos_to_expr_1(T, Start, End) || T <- G]
			  || G <- Ts],
		    lists:append(R0)
	    end;
       (S > End) or (E < Start) -> [];
       (S < Start) or (E > End) ->
	    Ts = refac_syntax:subtrees(Tree),
	    R0 = [[pos_to_expr_1(T, Start, End) || T <- G]
		  || G <- Ts],
	    lists:append(R0);
       true -> []
    end.


%% =====================================================================
%% get the list expressions enclosed by start and end locations.

%%-spec(pos_to_expr_list(Tree::syntaxTree(), Start::pos(), End::pos()) ->
%%	     [syntaxTree()]).

pos_to_expr_list(AnnAST, Start, End) ->
    Es = pos_to_expr_list_1(AnnAST, Start, End, fun is_expr/1),
    get_expr_list(Es).

pos_to_expr_or_pat_list(AnnAST, Start, End) ->
    F = fun(E) ->is_expr(E) orelse is_pattern(E) end,
    Es =pos_to_expr_list_1(AnnAST, Start, End, F),
    get_expr_list(Es).
 
pos_to_expr_list_1(Tree, Start, End, F) ->
    {S, E} = get_range(Tree),
    if (S >= Start) and (E =< End) ->
	    case F(Tree) of
		true ->
		    [Tree];
		_ ->
		    Ts = refac_syntax:subtrees(Tree),
		    [[lists:append(pos_to_expr_list_1(T, Start, End, F))|| T <- G]
		     || G <- Ts]
	    end;
       (S > End) or (E < Start) -> [];
       (S < Start) or (E > End) ->
	    Ts = refac_syntax:subtrees(Tree),
	    [[lists:append(pos_to_expr_list_1(T, Start, End, F)) || T <- G]
	     || G <- Ts];
       true -> []
    end.

get_expr_list(Es) ->
    case [E|| E<-Es, lists:flatten(E)/=[]] of 
	[] ->
	    [];
	[H|_T] -> 
	    get_expr_list_1(H)
    end.

get_expr_list_1(L) ->
    F = fun (E) -> not is_list(E) orelse E == [] end,
    case lists:all(F, L) of
      true ->
	  [E || E <- L, E /= []];
      false ->
	  get_expr_list(L)
    end.



%% ===========================================================================
%% @spec expr_to_fun(Tree::syntaxTree(), Exp::syntaxTree())->
%%                   {ok, syntaxTree()} | {error, none}
%%
%% @doc Return the AST of the function to which Exp (an expression node) belongs.

%%-spec(expr_to_fun(Tree::syntaxTree(), Exp::syntaxTree())->{ok, syntaxTree()} | {error, none}).
expr_to_fun(Tree, Exp) ->
    Res = expr_to_fun_1(Tree, Exp),
    case Res of 
	[H|_T] -> {ok, H};
	_ -> {error, none}
    end.
    
expr_to_fun_1(Tree, Exp) ->
    {Start, End} = get_range(Exp),
    {S, E} = get_range(Tree),
    if (S < Start) and (E >= End) ->
	   case refac_syntax:type(Tree) of
	     function -> [Tree];
	     _ ->
		 Ts = refac_syntax:subtrees(Tree),
		 R0 = [[expr_to_fun_1(T, Exp) || T <- G] || G <- Ts],
		 lists:flatten(R0)
	   end;
       true -> []
    end.

%% =====================================================================
%% @spec is_var_name(Name:: [any()])-> boolean()
%% @doc Return true if a string is lexically a  variable name.

%%-spec(is_var_name(Name:: [any()])-> boolean()).
is_var_name(Name) ->
    case Name of
	[] -> false;
	[H] -> is_upper(H) and (H=/=95);
	[H | T] -> (is_upper(H) or (H == 95)) and is_var_name_tail(T)
    end.

is_var_name_tail(Name) ->
    case Name of
      [H | T] ->
	  (is_upper(H) or is_lower(H) or is_digit(H) or (H == 64) or (H == 95)) and
	    is_var_name_tail(T);
      [] -> true
    end.

is_upper(L) -> (L >= 65) and (90 >= L).

is_lower(L) -> (L >= 97) and (122 >= L).

is_digit(L) -> (L >= 48) and (57 >= L).


%% =====================================================================
%% @spec is_fun_name(Name:: [any()])-> boolean()
%% @doc Return true if a name is lexically a function name.

%%-spec(is_fun_name(Name:: [any()])-> boolean()).
is_fun_name(Name) ->
    case Name of
      [H | T] -> is_lower(H) and is_var_name_tail(T);
      [] -> false
    end.



%% =====================================================================
%% @spec is_expr(Node:: syntaxTree())-> boolean()
%% @doc Return true if an AST node represents an expression.
%%-spec(is_expr(Node:: syntaxTree())-> boolean()).
is_expr(Node) ->
    As = refac_syntax:get_ann(Node),
    case lists:keysearch(category, 1, As) of
      {value, {category, C}} ->
	  case C of
	      expression -> true;
	      guard_expression -> true;
	      application_op -> true;
	      generator -> true;
	    _ -> false
	  end;
      _ -> false
    end.

%% =====================================================================
%% @spec is_pattern(Node:: syntaxTree())-> boolean()
%% @doc Return true if an AST node represents a pattern.

%%-spec(is_pattern(Node:: syntaxTree())-> boolean()).
is_pattern(Node) ->
    As = refac_syntax:get_ann(Node),
    case lists:keysearch(category, 1, As) of
      {value, {category, C}} ->
	  case C of
	    pattern -> true;
	    _ -> false
	  end;
      _ -> false
    end.

%% ============================================================================
%% @spec get_range(Node::syntaxTree())-> {Pos, Pos}
%%       Pos={integer(), integer()}
%%
%% @doc Return the start and end location of the syntax phrase in the code.

%%-spec(get_range(Node::syntaxTree())-> {pos(), pos()}).
get_range(Node) ->
    As = refac_syntax:get_ann(Node),
    case lists:keysearch(range, 1, As) of
      {value, {range, {S, E}}} -> {S, E};
      _ -> {?DEFAULT_LOC,
	   ?DEFAULT_LOC} 
    end.
%% =====================================================================
%% @spec get_var_exports(Node::syntaxTree())-> [{atom(), pos()}]
%% @doc Return the exported variables of an AST node.

%%-spec(get_var_exports(Node::[syntaxTree()]|syntaxTree())-> [{atom(),pos()}]).
get_var_exports(Nodes) when is_list(Nodes) ->
    lists:flatmap(fun(Node) -> get_var_exports(Node) end, Nodes);
get_var_exports(Node) ->
    get_var_exports_1(refac_syntax:get_ann(Node)).

get_var_exports_1([{bound, B} | _Bs]) -> B; %% Think about this again!!
get_var_exports_1([_ | Bs]) -> get_var_exports_1(Bs);
get_var_exports_1([]) -> [].

%% =====================================================================
%% @spec get_free_vars(Node::syntaxTree())-> [{atom(),pos()}]
%% @doc Return the free variables of an AST node.

%%-spec(get_free_vars(Node::[syntaxTree()]|syntaxTree())-> [{atom(),pos()}]).
get_free_vars(Nodes) when is_list(Nodes) ->
    FBVs= lists:map(fun(Node) ->
			  {get_free_vars(Node), get_bound_vars(Node)}
		  end, Nodes),
    {FVs, BVs} = lists:unzip(FBVs),
    lists:usort(lists:append(FVs)) -- lists:usort(lists:append(BVs));
get_free_vars(Node) ->
    get_free_vars_1(refac_syntax:get_ann(Node)).

get_free_vars_1([{free, B} | _Bs]) -> B;
get_free_vars_1([_ | Bs]) -> get_free_vars_1(Bs);
get_free_vars_1([]) -> [].


%% =====================================================================
%% @spec get_bound_vars(Node::syntaxTree())-> [{atom(),pos()}]
%% @doc Return the bound variables of an AST node.



%%-spec(get_bound_vars(Node::[syntaxTree()]|syntaxTree())-> [{atom(),pos()}]).
get_bound_vars(Nodes) when is_list(Nodes)->
    lists:usort(lists:flatmap(fun(Node) ->get_bound_vars(Node) end, Nodes));			   
get_bound_vars(Node) ->
    lists:usort(refac_syntax_lib:fold(fun(N, Acc) ->
			      get_bound_vars_1(refac_syntax:get_ann(N))++Acc
		      end, [], Node)).
					       
get_bound_vars_1([{bound, B} | _Bs]) -> B;
get_bound_vars_1([_ | Bs]) -> get_bound_vars_1(Bs);
get_bound_vars_1([]) -> [].

%% =====================================================================
%% @spec get_env_vars(Node::syntaxTree())-> [atom()]
%% @doc Return the environment variables of an AST node.

%%-spec(get_env_vars(Node::syntaxTree())-> [{atom(), pos()}]).
get_env_vars(Node) ->
    get_env_vars_1(refac_syntax:get_ann(Node)).

get_env_vars_1([{env, B} | _Bs]) -> B;
get_env_vars_1([_ | Bs]) -> get_env_vars_1(Bs);
get_env_vars_1([]) -> [].


%%===============================================================================
%% @spec inscope_funs(ModuleInfo) -> [{ModName, FunName, Arity}]
%%       ModuleInfo = [{Key, term()}]
%%       Key = attributes | errors | exports | functions | imports | module
%%             | records | rules | warnings
%%       ModName = atom()
%%       FunName = atom()
%%       Arity = integer()
%%
%% @doc Returns the functions that are inscope (either imported by the 
%% module or defined within the module) in the current module.
%% @TODO: Think about the interface of this function again.

%%-spec(inscope_funs(moduleInfo()) -> [{atom(), atom(), integer()}]).
inscope_funs(ModuleInfo) ->
    case lists:keysearch(module, 1, ModuleInfo) of
      {value, {module, M}} ->
	  Imps = case lists:keysearch(imports, 1, ModuleInfo) of
		   {value, {imports, I}} ->
		       lists:append([lists:map(fun ({F, A}) -> {M1, F, A} end, Fs) || {M1, Fs} <- I]);
		   _ -> []
		 end,
	  Funs = case lists:keysearch(functions, 1, ModuleInfo) of
		   {value, {functions, Fs}} -> lists:map(fun ({F, A}) -> {M, F, A} end, Fs);
		   _ -> []
		 end,
	  PreDefinedFuns=[{M, module_info, 1}, {M, module_info, 2}, {M, record_info, 2}],
	  Imps ++ Funs ++ PreDefinedFuns;
      _ -> []
    end.

%%===============================================================================
%% @spec is_exported({FunName::atom(), Arity::integer()},ModuleInfo) -> boolean()
%%       ModuleInfo = [{Key, term()}]
%%       Key = attributes | errors | exports | functions | imports | module
%%             | records | rules | warnings
%% @doc Return true if the function is exported by its defining module.
%% @TODO: Think about the interface of this function again.

%%-spec(is_exported({FunName::atom(), Arity::integer()},ModInfo::moduleInfo()) -> boolean()).
is_exported({FunName, Arity}, ModInfo) ->
    ImpExport = case lists:keysearch(attributes, 1, ModInfo) of
		    {value, {attributes, Attrs}} -> 
			lists:member({compile, export_all}, Attrs);
		    false -> false
		end,
    ExpExport= 	case lists:keysearch(exports, 1, ModInfo) of
		    {value, {exports, ExportList}} ->
			 lists:member({FunName, Arity}, ExportList);
		    _ -> false
		end,
    ImpExport or ExpExport.
		

%% =====================================================================
%% @spec update_ann(Node::syntaxTree(), {Key::atom(), Val::term()}) -> syntaxTree()
%% @doc Update a specific annotation of the Node with the given one.
%% if the kind of annotation already exists in the AST node, the annotation 
%% value is replaced with the new one, otherwise the given annotation info 
%% is added to the node.
%%-spec(update_ann(Node::syntaxTree(), {Key::atom(), Val::anyterm()}) -> syntaxTree()).
update_ann(Tree, {Key, Val}) ->
    As0 = refac_syntax:get_ann(Tree),
    As1 = case lists:keysearch(Key, 1, As0) of
	    {value, _} -> lists:keyreplace(Key, 1, As0, {Key, Val});
	    _ -> As0 ++ [{Key, Val}]
	  end,
    refac_syntax:set_ann(Tree, As1).

%% =====================================================================
%% @spec reset_attrs(Node::syntaxTree()) -> syntaxTree()
%% @doc Reset all the annotations in the subtree to the default (empty) annotation.

%%-spec(reset_attrs(Node::syntaxTree()) -> syntaxTree()).
reset_attrs(Node) ->
    refac_util:full_buTP(fun (T, _Others) -> refac_syntax:set_ann(T, []) end, Node, {}).


%%===============================================================================
%% @spec get_client_files(File::filename(), SearchPaths::[dir()]) -> [filename()]
%% @doc Return the list of files (Erlang modules) which make use of the functions 
%% defined in File.

%%-spec(get_client_files(File::filename(), SearchPaths::[dir()]) -> [filename()]).
get_client_files(File, SearchPaths) ->
    File1 = filename:absname(normalise_file_name(File)),
    ClientFiles = wrangler_modulegraph_server:get_client_files(File1, SearchPaths),
    case ClientFiles of
	[] ->
	    ?wrangler_io("\nWARNING: this module does not have "
		      "any client modules, please check the "
		      "search paths to ensure that this is "
		      "correct!\n",[]);
	_ -> ok
    end, 
    HeaderFiles = expand_files(SearchPaths, ".hrl"),
    ClientFiles ++ HeaderFiles.

normalise_file_name(Filename) ->
    filename:join(filename:split(Filename)).


%% =====================================================================
%% @spec expand_files(FileDirs::[filename()|dir()], Ext::string()) -> [filename()]
%% @doc Recursively collect all the files with the given file extension 
%%  in the specified directoris/files.

%%-spec(expand_files(FileDirs::[filename()|dir()], Ext::string()) -> [filename()]).
expand_files(FileDirs, Ext) ->
    expand_files(FileDirs, Ext, []).

expand_files([FileOrDir | Left], Ext, Acc) ->
    case filelib:is_dir(FileOrDir) of
      true ->
	  {ok, List} = file:list_dir(FileOrDir),
	  NewFiles = [filename:join(FileOrDir, X)
		      || X <- List, filelib:is_file(filename:join(FileOrDir, X)), filename:extension(X) == Ext],
	  NewDirs = [filename:join(FileOrDir, X) || X <- List, filelib:is_dir(filename:join(FileOrDir, X))],
	  expand_files(NewDirs ++ Left, Ext, NewFiles ++ Acc);
      false ->
	  case filelib:is_regular(FileOrDir) of
	    true ->
		case filename:extension(FileOrDir) == Ext of
		  true -> expand_files(Left, Ext, [FileOrDir | Acc]);
		  false -> expand_files(Left, Ext, Acc)
		end;
	    _ -> expand_files(Left, Ext, Acc)
	  end
    end;
expand_files([], _Ext, Acc) -> ordsets:from_list(Acc).


%% =====================================================================
%% @spec get_modules_by_file(Files::[filename()]) -> [{atom(), dir()}]
%% @doc The a list of files to a list of two-element tuples, with the first 
%% element of the tuple being the module name, and the second element 
%% binding the directory name of the file to which the module belongs.

%%-spec(get_modules_by_file(Files::[filename()]) -> [{atom(), dir()}]).
get_modules_by_file(Files) ->
    get_modules_by_file(Files, []).

get_modules_by_file([File | Left], Acc) ->
    BaseName = filename:basename(File, ".erl"),
    Dir = filename:dirname(File),
    get_modules_by_file(Left, [{list_to_atom(BaseName), Dir} | Acc]);
get_modules_by_file([], Acc) -> lists:reverse(Acc).


%% =====================================================================
%% @spec write_refactored_files(Files::[{OldFileName::filename(), NewFileName::filename(),
%%                             AST::syntaxTree()}])-> [ok|{error, term()}]
%% @doc Pretty-print the abstract syntax trees to a files, and add the previous 
%% version to history for undo purpose. <code>Files</code> is a list of three element 
%% tuples. The first element in the tuple is the original file name, the second element 
%% is the new file name if the filename has been changed by the refactoring, otherwise it 
%% should be the same as the first element, and the third element in the tuple is the 
%% AST represention of the file.

%% TODO: This function should not longer be used.
%%-spec(write_refactored_files([{{filename(),filename()},syntaxTree()}]) -> 'ok').
write_refactored_files(Files) ->
    F = fun ({{File1, File2}, AST}) ->
		FileFormat = file_format(File1),
		if File1 /= File2 ->
		       file:delete(File1);
		   true -> ok
		end,
		file:write_file(File2, list_to_binary(refac_prettypr:print_ast(FileFormat, AST)))
	end,
    Res =lists:map(F, Files),
    case lists:all(fun(R) -> R == ok end, Res) of 
	true -> ok;
	_ -> throw({error, "Wrangler failed to rewrite the refactored files."})
    end.

write_refactored_files_for_preview(Files, LogMsg) ->
    F = fun(FileAST) ->
		case FileAST of 
		    {{FileName,NewFileName}, AST} ->
			FileFormat = file_format(FileName),
			SwpFileName = filename:rootname(FileName, ".erl") ++ ".erl.swp",  %% .erl.swp or .swp.erl?
			case file:write_file(SwpFileName, list_to_binary(refac_prettypr:print_ast(FileFormat, AST))) of 
			    ok -> {{FileName,NewFileName, false},SwpFileName};
			    {error,Reason} -> Msg = io_lib:format("Wrangler could not write to directory ~s: ~w \n",
								  [filename:dirname(FileName), Reason]),
					      throw({error, Msg})
			end;			
		    {{FileName,NewFileName, IsNew}, AST} ->
			FileFormat = file_format(FileName),
			SwpFileName = filename:rootname(FileName, ".erl") ++ ".erl.swp", 
			case file:write_file(SwpFileName, list_to_binary(refac_prettypr:print_ast(FileFormat, AST))) of 
			    ok -> {{FileName,NewFileName, IsNew},SwpFileName};
			    {error, Reason}  -> 
				Msg = io_lib:format("Wrangler could not write to directory ~s: ~w \n",
						    [filename:dirname(FileName), Reason]),
				throw({error, Msg})
			end
		end
	end,
    FilePairs = lists:map(F, Files),
    case lists:any(fun(R) -> R == error end, FilePairs) of 
	true -> lists:foreach(fun(P) ->
				      case P of 
					  error -> ok;
					  {_,SwpF} -> file:delete(SwpF)
				      end
			      end, FilePairs),
		throw({error, "Wrangler failed to output the refactoring result."});
	_ -> wrangler_preview_server:add_files({FilePairs, LogMsg})
    end.


write_refactored_files(FileName, AnnAST, Editor, Cmd) ->
    case Editor of
      emacs ->
	  refac_util:write_refactored_files_for_preview([{{FileName, FileName}, AnnAST}], Cmd),
	  {ok, [FileName]};
      eclipse ->
	  Content = refac_prettypr:print_ast(refac_util:file_format(FileName), AnnAST),
	  {ok, [{FileName, FileName, Content}]}
    end.

write_refactored_files(Results, Editor, Cmd) ->
    case Editor of
      emacs ->
	  refac_util:write_refactored_files_for_preview(Results, Cmd),
	  ChangedFiles = lists:map(fun ({{F, _F}, _AST}) -> F end, Results),
	  ?wrangler_io("The following files are to be changed by this refactoring:\n~p\n",
		       [ChangedFiles]),
	  {ok, ChangedFiles};
      eclipse ->
	  Res = lists:map(fun ({{OldFName, NewFName}, AST}) ->
				  {OldFName, NewFName,
				   refac_prettypr:print_ast(refac_util:file_format(OldFName), AST)}
			  end, Results),
	  {ok, Res}
    end.
%% =====================================================================
%% @spec tokenize(File::filename()) -> [token()]
%% @doc Tokenize an Erlang file into a list of tokens.

%%-spec(tokenize(File::filename(), WithLayout::boolean(), TabWidth::integer()) -> [token()]).
tokenize(File, WithLayout, TabWidth) ->
    {ok, Bin} = file:read_file(File),
    S = erlang:binary_to_list(Bin),
    case WithLayout of 
	true -> 
	    {ok, Ts, _} = refac_scan_with_layout:string(S, {1,1}, TabWidth, file_format(File)),
	    Ts;
	_ -> {ok, Ts, _} = refac_scan:string(S, {1,1}, TabWidth,file_format(File)),
	     Ts
    end.


%% =====================================================================
%% @spec parse_annotate_file(FName::filename(), ByPassPreP::boolean(), SearchPaths::[dir()])
%%                           -> {ok, {syntaxTree(), ModInfo}} | {error, string()}
%%
%%       ModInfo = [{Key, term()}]
%%       Key = attributes | errors | exports | functions | imports | module
%%             | records | rules | warnings
%%
%% @doc Parse an Erlang file, and annotate the abstract syntax tree with static semantic 
%% information. As to the parameters, FName is the name of the file to parse;  ByPassPreP 
%% is a bool value, and 'true' means to use the parse defined in refac_epp_dodger 
%% (which does not expand macros), 'false' means to use the parse defined in refac_epp
%% (which expands macros); SeachPaths is the list of directories to search for related 
%% Erlang files. 
%% The following annotations are added to the AST generated by the parser.
%% <ul>
%%     <li> <code> {env, [Var]}</code>, representing the input enrironment of 
%%     the subtree. </li>
%%
%%     <li> <code> {bound, [Var]} </code>, representing the variables that are 
%%      bound in the subtree. </li>
%%
%%     <li> <code> {free, [Var]}</code>, representing the free variables in the 
%%     subtree </li>
%%   
%%     <li> <code> {range, {Pos, Pos}} </code>, representing the start and end location 
%%     of subtree in the program source. </li>
%%    
%%     <li> <code> {category, atom()} </code>, representing the kind of the syntex phrase 
%%      represented by the subtree. </li>
%%
%%     <li> <code> {def, [Pos]} </code>, representing the defining positions of the variable 
%%     represented by the subtree (only when the subtree does represent a variable). </li>
%%
%%     <li> <code> {fun_def, {Mod, FunName, Arity, Pos, Pos}} </code>, representing the binding 
%%     information of the function represented by the subtree (only when the subtree
%%     represents a function definition, a function application, or an arity qualifier).
%%      </li>
%% </ul>
%%  <code>Var</code>  is a two-element tuple whose first element is an atom representing 
%%   the variable name, second element representing the variable's defining position. 
%%
%% @type syntaxTree(). An abstract syntax tree. The <code>erl_parse</code> "parse tree" 
%%  representation is a subset of the <code>syntaxTree()</code> representation.
%% 
%%  For the data structures used by the AST nodes, please refer to <a href="refac_syntax.html"> refac_syntax </a>.

%%-spec(parse_annotate_file(FName::filename(), ByPassPreP::boolean(), SearchPaths::[dir()])
%%                           -> {ok, {syntaxTree(), moduleInfo()}}).
parse_annotate_file(FName, ByPassPreP, SearchPaths) ->
    parse_annotate_file(FName, ByPassPreP, SearchPaths, ?DEFAULT_TABWIDTH).

%%-spec(parse_annotate_file(FName::filename(), ByPassPreP::boolean(), SearchPaths::[dir()], TabWidth::integer())
%%      -> {ok, {syntaxTree(), moduleInfo()}}).
parse_annotate_file(FName, ByPassPreP, SearchPaths, TabWidth) ->
    FileFormat =file_format(FName),     
    case whereis(wrangler_ast_server) of  
	undefined ->        %% this should not happen with Wrangler + Emacs.
	    ?wrangler_io("wrangler_ast_aserver is not defined\n",[]),
	    parse_annotate_file_1(FName, ByPassPreP, SearchPaths, TabWidth, FileFormat);
	_ ->
	    wrangler_ast_server:get_ast({FName, ByPassPreP, SearchPaths, TabWidth, FileFormat})
    end.
     


%%-spec(parse_annotate_file_1(FName::filename(), ByPassPreP::boolean(), SearchPaths::[dir()], integer(), atom())
%%      -> {ok, {syntaxTree(), moduleInfo()}}).
parse_annotate_file_1(FName, true, SearchPaths, TabWidth, FileFormat) ->
    case refac_epp_dodger:parse_file(FName, [{tab, TabWidth}, {format, FileFormat}]) of
	{ok, Forms} -> 
	    Dir = filename:dirname(FName),
	    DefaultIncl2 = [filename:join(Dir, X) || X <-default_incls()],
	    Includes = SearchPaths++DefaultIncl2,
	    {Info0, Ms}=case refac_epp:parse_file(FName, Includes, [], TabWidth, FileFormat) of
			{ok, Fs, {MDefs, MUses}}  -> 
			    ST = refac_recomment:recomment_forms(Fs,[]),
			    Info1= refac_syntax_lib:analyze_forms(ST),
			    Ms1={dict:from_list(MDefs), dict:from_list(MUses)},
			    {Info1, Ms1};			
			_ -> {[], {dict:from_list([]), dict:from_list([])}}
		    end,	
	    Comments = refac_comment_scan:file(FName),
	    SyntaxTree = refac_recomment:recomment_forms(Forms, Comments),
	    Info = refac_syntax_lib:analyze_forms(SyntaxTree),
	    Info2 = merge_module_info(Info0, Info),
	    AnnAST0 = annotate_bindings(FName, SyntaxTree, Info2, Ms, TabWidth),
	    AnnAST= refac_type_annotation:type_ann_ast(FName, Info2, AnnAST0, SearchPaths, TabWidth),
	    {ok, {AnnAST, Info2}};
	{error, Reason} -> erlang:error(Reason)
    end;     

parse_annotate_file_1(FName, false, SearchPaths, TabWidth, FileFormat) ->
    Dir = filename:dirname(FName),
    DefaultIncl2 = [filename:join(Dir, X) || X <-default_incls()],
    Includes = SearchPaths++DefaultIncl2,
   case refac_epp:parse_file(FName, Includes,[], TabWidth, FileFormat) of 
       {ok, Forms, Ms} -> Forms1 =  lists:filter(fun(F) ->
							case F of 
							    {attribute, _, file, _} -> false;
							    {attribute, _, type, {{record, _}, _, _}} -> false;
							    _ -> true
							end
						end, Forms),
			 %% I wonder whether the all the following is needed;
			 %% we should never perform a transformation on an AnnAST from resulted from refac_epp;
			  SyntaxTree = refac_recomment:recomment_forms(Forms1,[]),
			  Info = refac_syntax_lib:analyze_forms(SyntaxTree),
			  AnnAST0 = annotate_bindings(FName, SyntaxTree, Info, Ms, TabWidth),
			  {ok, {AnnAST0, Info}};      
       {error, Reason} -> erlang:error(Reason)
   end.

merge_module_info(Info1, Info2) ->
    Info = lists:usort(Info1 ++ Info2),
    F = fun(Attr) ->
		lists:usort(lists:append(
			      [Vs||{Attr1,Vs} <- Info, 
				   Attr1==Attr]))
	end,
    M = case lists:keysearch(module, 1, Info) of
		 {value, R} ->
		     R;
		 _ -> {module, []}
	     end,
    NewInfo=[M, {exports,F(exports)}, {module_imports, F(module_imports)},
	     {imports, F(imports)}, {attributes,F(attributes)},
	     {records, F(records)}, {errors, F(errors)}, {warnings, F(warnings)},
	     {functions, F(functions)}, {rules, F(rules)}],
    [{A,V}||{A, V}<-NewInfo, V=/=[]].
	     

    
    
   
annotate_bindings(FName, AST, Info, Ms, TabWidth) ->
    Toks = tokenize(FName, true, TabWidth),
    AnnAST0 = refac_syntax_lib:annotate_bindings(add_tokens(add_range(AST, Toks), Toks), ordsets:new(), Ms),
    add_category(refac_annotate_ast:add_fun_define_locations(AnnAST0, Info)).
 

%@spec add_tokens(FName::filename(), SyntaxTree::syntaxTree()) -> syntaxTree()
%%@Attach tokens to each form in the AST.
add_tokens(SyntaxTree, Toks) ->
    Fs = refac_syntax:form_list_elements(SyntaxTree),
    rewrite(SyntaxTree, refac_syntax:form_list(do_add_tokens(Toks, Fs))).

do_add_tokens(Toks, Fs) ->
    do_add_tokens(Toks, lists:reverse(Fs), []).

do_add_tokens(_, [], NewFs) ->
     NewFs;
do_add_tokens(Toks, [F|Fs], NewFs)->
    {StartPos, RemFs}  =
	case refac_syntax:type(F) of 
	    error_marker ->
		case Fs of 
		    [] -> {{1,1},[]};
		    _ ->Fs1 = lists:dropwhile(fun(F1) ->
						      lists:member(refac_syntax:type(F1),[comment, error_marker])
					      end, Fs),
			case Fs1 of 
			    [] ->
				{{1, 1}, []};
			    _ -> {_, {Line, _}} = get_range(hd(Fs1)),
				 {{Line+1, 1}, Fs1}
			end
		end;
	    _ -> case refac_syntax:get_precomments(F) of 
		     [] -> {Start, _End} = get_range(F),
			   {Start, Fs};
		     [Com|_Tl] -> {refac_syntax:get_pos(Com),Fs}
		 end
	end,
    {Toks1, Toks2} = lists:splitwith(fun(T) ->
					     element(2,T) < StartPos
				     end, Toks),
    {Toks11, Toks12} = lists:splitwith(fun(T) -> 
					       element(1,T) == whitespace 
				       end, lists:reverse(Toks1)),
    {FormToks, RemainToks} = 
	case Toks12 of 
	    [] ->  {Toks,[]};
	    [H|_T] -> Line1 = element(1, element(2, H)), 
		      {Toks13, Toks14} = lists:splitwith(fun(T) -> 
								 element(1, element(2,T)) == Line1 
							 end, lists:reverse(Toks11)),
		      {Toks14++Toks2, lists:reverse(Toks12)++Toks13}					
	end,
    F1 =refac_syntax:add_ann({toks, FormToks}, F),
    do_add_tokens(RemainToks, RemFs, [F1|NewFs]).


%% ============================================================================
%% @spec get_toks(Node::syntaxTree())-> [token()]
%%       
%%
%% @doc Return the token list annoated to a form.

%%-spec(get_toks(Node::syntaxTree())-> [token()]).
get_toks(Node) ->
    As = refac_syntax:get_ann(Node),
    case lists:keysearch(toks, 1, As) of
      {value, {toks, Toks}} -> Toks;
      _ -> []
    end.
		
     


%%@spec analyze_free_vars(SyntaxTree::syntaxTree()) ->ok|{error, string()} 
%%@doc Check whether an abstract syntax phrase contains any free variables.

%%-spec(analyze_free_vars(SyntaxTree::syntaxTree()) ->ok|{error, string()}).
analyze_free_vars(SyntaxTree) ->
    Ann = refac_syntax:get_ann(SyntaxTree),
    case lists:keysearch(free, 1, Ann) of
      {value, {free, FrVars}} ->
	  case FrVars of
	    [] -> ok;
	     Ls -> {error, "Unbound variable(s) found: " ++ show_fv_vars(Ls)}
	  end;
      _ -> ok
    end.

show_fv_vars([]) -> ".";
show_fv_vars([{A, {Line, Col}} | T]) ->
    T1 = if T == [] -> ".";
	    true -> ", " ++ show_fv_vars(T)
	 end,
    atom_to_list(A) ++ " at: {" ++ integer_to_list(Line) ++ "," ++ integer_to_list(Col) ++ "}" ++ T1.



add_range(AST, Toks) ->
    full_buTP(fun do_add_range/2, AST, Toks).
do_add_range(Node, Toks) ->
    
    {L, C} = case refac_syntax:get_pos(Node) of
	       {Line, Col} -> {Line, Col};
	       Line -> {Line, 0}
	     end,
    case refac_syntax:type(Node) of
      variable ->
	  Len = length(refac_syntax:variable_literal(Node)),
	  refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node);
      atom ->
	  Lit = refac_syntax:atom_literal(Node),
	  case hd(Lit) of
	    39 -> Toks1 = lists:dropwhile(fun (T) -> token_loc(T) =< {L, C} end, Toks),
		  case Toks1   %% this should not happen;
		      of
		    [] -> Len = length(atom_to_list(refac_syntax:atom_value(Node))),  %% This is problematic!!
			  refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node);
		    _ -> {L2, C2} = token_loc(hd(Toks1)),
			 refac_syntax:add_ann({range, {{L, C}, {L2, C2 - 1}}}, Node)
		  end;
	    _ -> Len = length(atom_to_list(refac_syntax:atom_value(Node))),  %% This is problematic!!
		 refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node)
	  end;
      operator ->
	  Len = length(atom_to_list(refac_syntax:atom_value(Node))),
	  refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node);
      char -> refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node);
      integer ->
	  Len = length(refac_syntax:integer_literal(Node)),
	  refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node);
      string ->
	  Toks1 = lists:dropwhile(fun (T) -> token_loc(T) < {L, C} end, Toks),
	  {Toks21, Toks22} = lists:splitwith(fun (T) -> is_string(T) orelse is_whitespace_or_comment(T) end, Toks1),
	  Toks3 = lists:filter(fun (T) -> is_string(T) end, Toks21),
	  case Toks3 of
	    [] ->
		Len = length(refac_syntax:string_literal(Node)),
		Toks23 = lists:takewhile(fun (T) -> token_loc(T) < {L, C + Len - 1} end, Toks22),
		Toks31 = lists:filter(fun (T) -> is_string(T) end, Toks23),
		case Toks31 of
		  [] ->
		      refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node);
		  _ ->
		      Node1 = refac_syntax:add_ann({range, {{L, C}, {L, C + Len - 1}}}, Node),
		      refac_syntax:add_ann({toks, Toks31}, Node1)
		end;
	    _ -> Toks4 = lists:takewhile(fun (T) -> is_whitespace_or_comment(T) end, lists:reverse(Toks21)),
		 {L3, C3} = case Toks4 of
			      [] -> token_loc(hd(Toks22));
			      _ -> token_loc(lists:last(Toks4))
			    end,
		 R = {token_loc(hd(Toks21)), {L3, C3 - 1}},
		 Node1 = refac_syntax:add_ann({range, R}, Node),
		 refac_syntax:add_ann({toks, Toks3}, Node1)
	  end;
      float ->
	  refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node); %% This is problematic.
      underscore -> refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node);
      eof_marker -> refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node);
      nil -> refac_syntax:add_ann({range, {{L, C}, {L, C + 1}}}, Node);
      module_qualifier ->
	  M = refac_syntax:module_qualifier_argument(Node),
	  F = refac_syntax:module_qualifier_body(Node),
	  {S1, _E1} = get_range(M),
	  {_S2, E2} = get_range(F),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      list ->
	  LP = ghead("refac_util:do_add_range,list", refac_syntax:list_prefix(Node)),
	  {{L1, C1}, {L2, C2}} = get_range(LP),
	  case refac_syntax:list_suffix(Node) of
	    none -> refac_syntax:add_ann({range, {{L1, C1 - 1}, {L2, C2 + 1}}}, Node);
	    Tail -> {_S2, {L3, C3}} = get_range(Tail), refac_syntax:add_ann({range, {{L1, C1 - 1}, {L3, C3}}}, Node)
	  end;
      application ->
	  O = refac_syntax:application_operator(Node),
	  Args = refac_syntax:application_arguments(Node),
	  {S1, E1} = get_range(O),
	  {S3, E3} = case Args of
		       [] -> {S1, E1};
		       _ -> La = glast("refac_util:do_add_range, application", Args),
			    {_S2, E2} = get_range(La),
			    {S1, E2}
		     end,
	  E31 = extend_backwards(Toks, E3, ')'),
	  refac_syntax:add_ann({range, {S3, E31}}, Node);
      case_expr ->
	  A = refac_syntax:case_expr_argument(Node),
	  Lc = glast("refac_util:do_add_range,case_expr", refac_syntax:case_expr_clauses(Node)),
	  {S1, _E1} = get_range(A),
	  {_S2, E2} = get_range(Lc),
	  S11 = extend_forwards(Toks, S1, 'case'),
	  E21 = extend_backwards(Toks, E2, 'end'),
	  refac_syntax:add_ann({range, {S11, E21}}, Node);
      clause ->
	  P = refac_syntax:get_pos(Node),
	  Body = glast("refac_util:do_add_range, clause", refac_syntax:clause_body(Node)),
	  {_S2, E2} = get_range(Body),
	  refac_syntax:add_ann({range, {P, E2}}, Node);
      catch_expr ->
	  B = refac_syntax:catch_expr_body(Node),
	  {S, E} = get_range(B),
	  S1 = extend_forwards(Toks, S, 'catch'),
	  refac_syntax:add_ann({range, {S1, E}}, Node);
      if_expr ->
	  Cs = refac_syntax:if_expr_clauses(Node),
	  add_range_to_list_node(Node, Toks, Cs, "refac_util:do_add_range, if_expr",
				 "refac_util:do_add_range, if_expr", 'if', 'end');
      cond_expr ->
	  Cs = refac_syntax:cond_expr_clauses(Node),
	  add_range_to_list_node(Node, Toks, Cs, "refac_util:do_add_range, cond_expr",
				 "refac_util:do_add_range, cond_expr", 'cond', 'end');
      infix_expr ->
	  Left = refac_syntax:infix_expr_left(Node),
	  Right = refac_syntax:infix_expr_right(Node),
	  {S1, _E1} = get_range(Left),
	  {_S2, E2} = get_range(Right),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      prefix_expr ->
	  Op = refac_syntax:prefix_expr_operator(Node),
	  Ar = refac_syntax:prefix_expr_argument(Node),
	  {S1, _E1} = get_range(Op),
	  {_S2, E2} = get_range(Ar),
	  %% E21 = extend_backwards(Toks, E2, ')'),  %% the parser should keey the parathesis!
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      conjunction ->
	  B = refac_syntax:conjunction_body(Node),
	  add_range_to_body(Node, B, "refac_util:do_add_range,conjunction", 
			    "refac_util:do_add_range,conjunction");
      disjunction ->
	  B = refac_syntax:disjunction_body(Node),	  
	  add_range_to_body(Node, B, "refac_util:do_add_range, disjunction",
			    "refac_util:do_add_range,disjunction");
      function ->
	  F = refac_syntax:function_name(Node),
	  Cs = refac_syntax:function_clauses(Node),
	  Lc = glast("refac_util:do_add_range,function", Cs),
	  {S1, _E1} = get_range(F),
	  {_S2, E2} = get_range(Lc),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      fun_expr ->
	  Cs = refac_syntax:fun_expr_clauses(Node),
	  S = refac_syntax:get_pos(Node),
	  Lc = glast("refac_util:do_add_range, fun_expr", Cs),
	  {_S1, E1} = get_range(Lc),
	  E11 = extend_backwards(Toks, E1,
				 'end'),   %% S starts from 'fun', so there is no need to extend forwards/
	  refac_syntax:add_ann({range, {S, E11}}, Node);
      arity_qualifier ->
	  B = refac_syntax:arity_qualifier_body(Node),
	  A = refac_syntax:arity_qualifier_argument(Node),
	  {S1, _E1} = get_range(B),
	  {_S2, E2} = get_range(A),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      implicit_fun ->
	  S = refac_syntax:get_pos(Node),
	  N = refac_syntax:implicit_fun_name(Node),
	  {_S1, E1} = get_range(N),
	  refac_syntax:add_ann({range, {S, E1}}, Node);
      attribute ->
	  Name = refac_syntax:attribute_name(Node),
	  Args = refac_syntax:attribute_arguments(Node),
	  case Args of
	    none -> {S1, E1} = get_range(Name),
		    S11 = extend_forwards(Toks, S1, '-'),
		    refac_syntax:add_ann({range, {S11, E1}}, Node);
	    _ -> case length(Args) > 0 of
		   true -> Arg = glast("refac_util:do_add_range,attribute", Args),
			   {S1, _E1} = get_range(Name),
			   {_S2, E2} = get_range(Arg),
			   S11 = extend_forwards(Toks, S1, '-'),
			   refac_syntax:add_ann({range, {S11, E2}}, Node);
		   _ -> {S1, E1} = get_range(Name),
			S11 = extend_forwards(Toks, S1, '-'),
			refac_syntax:add_ann({range, {S11, E1}}, Node)
		 end
	  end;
      generator ->
	  P = refac_syntax:generator_pattern(Node),
	  B = refac_syntax:generator_body(Node),
	  {S1, _E1} = get_range(P),
	  {_S2, E2} = get_range(B),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      tuple ->
	  Es = refac_syntax:tuple_elements(Node),
	  case length(Es) of
	    0 -> refac_syntax:add_ann({range, {{L, C}, {L, C + 1}}}, Node);
	    _ ->
		add_range_to_list_node(Node, Toks, Es, "refac_util:do_add_range, tuple", 
				       "refac_util:do_add_range, tuple",
				       '{', '}')
	  end;
      list_comp ->
	  T = refac_syntax:list_comp_template(Node),
	  B = glast("refac_util:do_add_range,list_comp", refac_syntax:list_comp_body(Node)),
	  {S1, _E1} = get_range(T),
	  {_S2, E2} = get_range(B),
	  S11 = extend_forwards(Toks, S1, '['),
	  E21 = extend_backwards(Toks, E2, ']'),
	  refac_syntax:add_ann({range, {S11, E21}}, Node);
      block_expr ->
	  Es = refac_syntax:block_expr_body(Node),
	  add_range_to_list_node(Node, Toks, Es, "refac_util:do_add_range, block_expr",
				 "refac_util:do_add_range, block_expr", 'begin', 'end');
      receive_expr ->
	  case refac_syntax:receive_expr_timeout(Node) of
	    none ->
		Cs = refac_syntax:receive_expr_clauses(Node),
		case length(Cs) of
		  0 -> refac_syntax:add_ann({range, {L, C}, {L, C}}, Node);
		  _ ->
		      add_range_to_list_node(Node, Toks, Cs, "refac_util:do_add_range, receive_expr1",
					     "refac_util:do_add_range, receive_expr1", 'receive', 'end')
		end;
	    _E ->
		Cs = refac_syntax:receive_expr_clauses(Node),
		A = refac_syntax:receive_expr_action(Node),
		case length(Cs) of
		  0 ->
		      {_S2, E2} = get_range(glast("refac_util:do_add_range, receive_expr2", A)),
		      refac_syntax:add_ann({range, {{L, C}, E2}}, Node);
		  _ ->
		      Hd = ghead("refac_util:do_add_range,receive_expr2", Cs),
		      {S1, _E1} = get_range(Hd),
		      {_S2, E2} = get_range(glast("refac_util:do_add_range, receive_expr3", A)),
		      S11 = extend_forwards(Toks, S1, 'receive'),
		      E21 = extend_backwards(Toks, E2, 'end'),
		      refac_syntax:add_ann({range, {S11, E21}}, Node)
		end
	  end;
      try_expr ->
	  B = refac_syntax:try_expr_body(Node),
	  After = refac_syntax:try_expr_after(Node),
	  {S1, _E1} = get_range(ghead("refac_util:do_add_range, try_expr", B)),
	  {_S2, E2} = case After of
			[] ->
			    Handlers = refac_syntax:try_expr_handlers(Node),
			    get_range(glast("refac_util:do_add_range, try_expr", Handlers));
			_ ->
			    get_range(glast("refac_util:do_add_range, try_expr", After))
		      end,
	  S11 = extend_forwards(Toks, S1, 'try'),
	  E21 = extend_backwards(Toks, E2, 'end'),
	  refac_syntax:add_ann({range, {S11, E21}}, Node);
      binary ->
	  Fs = refac_syntax:binary_fields(Node),
	  case Fs == [] of
	    true -> refac_syntax:add_ann({range, {{L, C}, {L, C + 3}}}, Node);
	      _ -> %% this should be changed when the parser is able 
                  %% to include location info for binary type qualifiers.
		  Hd = ghead("do_add_range:binary",Fs),
		  {S1, _E1} = get_range(Hd), 
		  S11 = extend_forwards(Toks, S1, "<<"),
		  E21= extend_backwards(Toks, S1,">>"),
		  refac_syntax:add_ann({range, {S11, E21}}, Node)
	  end;
      binary_field ->
	  Body = refac_syntax:binary_field_body(Node),
	  Types = refac_syntax:binary_field_types(Node),
	  {S1, E1} = get_range(Body),
	  {_S2, E2} = if Types == [] -> {S1, E1};
			 true -> get_range(glast("refac_util:do_add_range,binary_field", Types))
		      end,
	  case E2> E1 of  %%Temporal fix; need to change refac_syntax to make the pos info correct.
	      true ->
		  refac_syntax:add_ann({range, {S1, E2}}, Node);
	      false ->
		   refac_syntax:add_ann({range, {S1, E1}}, Node)
	  end;
      match_expr ->
	  P = refac_syntax:match_expr_pattern(Node),
	  B = refac_syntax:match_expr_body(Node),
	  {S1, _E1} = get_range(P),
	  {_S2, E2} = get_range(B),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      form_list ->
	  Es = refac_syntax:form_list_elements(Node),
	  
	  add_range_to_body(Node, Es, "refac_util:do_add_range, form_list", 
			    "refac_util:do_add_range, form_list");
      parentheses ->
	  B = refac_syntax:parentheses_body(Node),
	  {S, E} = get_range(B),
	  S1 = extend_forwards(Toks, S, '('),
	  E1 = extend_backwards(Toks, E, ')'),
	  refac_syntax:add_ann({range, {S1, E1}}, Node);
      class_qualifier ->
	  A = refac_syntax:class_qualifier_argument(Node),
	  B = refac_syntax:class_qualifier_body(Node),
	  {S1, _E1} = get_range(A),
	  {_S2, E2} = get_range(B),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      qualified_name ->
	  Es = refac_syntax:qualified_name_segments(Node),
	  
	  add_range_to_body(Node, Es, "refac_util:do_add_range, qualified_name",
			    "refac_util:do_add_range, qualified_name");
      query_expr ->
	  B = refac_syntax:query_expr_body(Node),
	  {S, E} = get_range(B),
	  refac_syntax:add_ann({range, {S, E}}, Node);
      record_field ->
	  Name = refac_syntax:record_field_name(Node),
	  {S1, E1} = get_range(Name),
	  Value = refac_syntax:record_field_value(Node),
	  case Value of
	    none -> refac_syntax:add_ann({range, {S1, E1}}, Node);
	    _ -> {_S2, E2} = get_range(Value), refac_syntax:add_ann({range, {S1, E2}}, Node)
	  end;
      typed_record_field ->   %% This is not correct; need to be fixed later!
	  Field = refac_syntax:typed_record_field(Node),
	  {S1, _E1} = get_range(Field),
	  Type = refac_syntax:typed_record_type(Node),
	  {_S2, E2} = get_range(Type),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      record_expr ->
	  Arg = refac_syntax:record_expr_argument(Node),
	  Type = refac_syntax:record_expr_type(Node),
	  Fields = refac_syntax:record_expr_fields(Node),
	  {S1, E1} = case Arg of
		       none -> get_range(Type);
		       _ -> get_range(Arg)
		     end,
	  case Fields of
	    [] -> E11 = extend_backwards(Toks, E1, '}'),
		  refac_syntax:add_ann({range, {S1, E11}}, Node);
	    _ ->
		{_S2, E2} = get_range(glast("refac_util:do_add_range,record_expr", Fields)),
		E21 = extend_backwards(Toks, E2, '}'),
		refac_syntax:add_ann({range, {S1, E21}}, Node)
	  end;
      record_access ->
	  Arg = refac_syntax:record_access_argument(Node),
	  Field = refac_syntax:record_access_field(Node),
	  {S1, _E1} = get_range(Arg),
	  {_S2, E2} = get_range(Field),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      record_index_expr ->
	  Type = refac_syntax:record_index_expr_type(Node),
	  Field = refac_syntax:record_index_expr_field(Node),
	  {S1, _E1} = get_range(Type),
	  {_S2, E2} = get_range(Field),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      comment ->
	  T = refac_syntax:comment_text(Node),
	  Lines = length(T),
	  refac_syntax:add_ann({range, {{L, C}, {L + Lines - 1,
						 length(glast("refac_util:do_add_range,comment", T))}}},
			       Node);
      macro ->
	  Name = refac_syntax:macro_name(Node),
	  Args = refac_syntax:macro_arguments(Node),
	  {_S1, E1} = get_range(Name),
	  case Args of
	    none -> refac_syntax:add_ann({range, {{L, C}, E1}}, Node);
	    Ls ->
		case Ls of
		  [] -> E21 = extend_backwards(Toks, E1, ')'),
			refac_syntax:add_ann({range, {{L, C}, E21}}, Node);
		  _ ->
		      La = glast("refac_util:do_add_range,macro", Ls),
		      {_S2, E2} = get_range(La),
		      E21 = extend_backwards(Toks, E2, ')'),
		      refac_syntax:add_ann({range, {{L, C}, E21}}, Node)
		end
	  end;
      size_qualifier ->
	  Body = refac_syntax:size_qualifier_body(Node),
	  Arg = refac_syntax:size_qualifier_argument(Node),
	  {S1, _E1} = get_range(Body),
	  {_S2, E2} = get_range(Arg),
	  refac_syntax:add_ann({range, {S1, E2}}, Node);
      error_marker ->
	  refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node);
      type ->   %% This is not correct, and need to be fixed!!
	  refac_syntax:add_ann({range, {{L, C}, {L, C}}}, Node);
      _ ->
	  ?wrangler_io("Unhandled syntax category:\n~p\n", [refac_syntax:type(Node)]),
	  Node
    end.

add_range_to_list_node(Node, Toks, Es, Str1, Str2, KeyWord1, KeyWord2) ->
    Hd = ghead(Str1, Es),
    La = glast(Str2, Es),
    {S1, _E1} = get_range(Hd),
    {_S2, E2} = get_range(La),
    S11 = extend_forwards(Toks, S1, KeyWord1),
    E21= extend_backwards(Toks, E2, KeyWord2),
    refac_syntax:add_ann({range, {S11, E21}}, Node).


add_range_to_body(Node, B, Str1, Str2) ->
    H = ghead(Str1, B),
    La = glast(Str2, B),
    {S1, _E1} = get_range(H),
    {_S2, E2} = get_range(La),
    refac_syntax:add_ann({range, {S1, E2}}, Node).
   
extend_forwards(Toks, StartLoc, Val) ->
    Toks1 = lists:takewhile(fun (T) -> token_loc(T) < StartLoc end, Toks),
    Toks2 = lists:dropwhile(fun (T) -> token_val(T) =/= Val end, lists:reverse(Toks1)),
    case Toks2 of
      [] -> StartLoc;
      _ -> token_loc(hd(Toks2))
    end.

extend_backwards(Toks, EndLoc, Val) ->
    Toks1 = lists:dropwhile(fun (T) -> token_loc(T) =< EndLoc end, Toks),
    Toks2 = lists:dropwhile(fun (T) -> token_val(T) =/= Val end, Toks1),
    case Toks2 of
      [] -> EndLoc;
      _ ->
	  {Ln, Col} = token_loc(hd(Toks2)),
	  {Ln, Col + length(atom_to_list(Val)) - 1}
    end.

token_loc(T) ->
    case T of
      {_, L, _V} -> L;
      {_, L1} -> L1
    end.

token_val(T) ->
    case T of
      {_, _, V} -> V;
      {V, _} -> V
    end.

%% =====================================================================
%% @spec add_category(Node::syntaxTree()) -> syntaxTree()
%% @doc Attach syntax category information to AST nodes.
%% =====================================================================
%%-spec(add_category(Node::syntaxTree()) -> syntaxTree()).
add_category(Node) ->
    case refac_syntax:type(Node) of
      form_list ->
	  Es = refac_syntax:form_list_elements(Node),
	  Es1 = lists:map(fun (E) -> add_category(E) end, Es),
	  Node1 = rewrite(Node, refac_syntax:form_list(Es1)),
	  refac_syntax:add_ann({category, form_list}, Node1);
      attribute -> add_category(Node, attribute);
      function -> add_category(Node, function);
      rule -> add_category(Node, rule);
      error_marker -> add_category(Node, error_marker);
      warning_marker -> add_category(Node, warning_marker);
      eof_marker -> add_category(Node, eof_marker);
      comment -> add_category(Node, comment);
     %%  macro -> add_category(Node, macro);
      _ -> add_category(Node, unknown)
    end.

add_category(Node, C) -> {Node1, _} = stop_tdTP(fun do_add_category/2, Node, C),
			 Node1.
do_add_category(Node, C) ->
    if is_list(Node) -> {lists:map(fun (E) -> add_category(E, C) end, Node), true};
       true ->
	   case refac_syntax:type(Node) of
	     clause ->
		 B = refac_syntax:clause_body(Node),
		 P = refac_syntax:clause_patterns(Node),
		 G = refac_syntax:clause_guard(Node),
		 B1 = add_category(B, expression),
		 P1 = add_category(P, pattern),
		 G1 = case G of
			none -> none;
			_ -> add_category(G, guard_expression)
		      end,
		 Node1 = rewrite(Node, refac_syntax:clause(P1, G1, B1)),
		 {refac_syntax:add_ann({category, clause}, Node1), true};
	     match_expr ->
		 P = refac_syntax:match_expr_pattern(Node),
		 B = refac_syntax:match_expr_body(Node),
		 P1 = add_category(P, pattern),
		 B1 = add_category(B, C),
		 Node1 = rewrite(Node, refac_syntax:match_expr(P1, B1)),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     operator -> {refac_syntax:add_ann({category, operator}, Node), true}; %% added to fix bug 13/09/2008.
	     application ->
		 Op = refac_syntax:application_operator(Node),
		 Args = refac_syntax:application_arguments(Node),
		 Op1 = add_category(Op, application_op),
		 Args1 = add_category(Args, C),
		 Node1 = rewrite(Node, refac_syntax:application(Op1, Args1)),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     arity_qualifier ->
		 Fun = add_category(refac_syntax:arity_qualifier_body(Node), arity_qualifier),
		 A = add_category(refac_syntax:arity_qualifier_argument(Node), arity_qualifier),
		 Node1 = refac_syntax:arity_qualifier(Fun, A),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     macro ->
		   Name = refac_syntax:macro_name(Node),
		   Args = refac_syntax:macro_arguments(Node),
		   Name1 = add_category(Name, macro_name),
		   Args1 = case Args of
			       none -> none;
			   _ -> add_category(Args, expression) %% should 'expression' be 'macro_args'?
			   end,
		   Node1 = rewrite(Node, refac_syntax:macro(Name1, Args1)),
		   {refac_syntax:add_ann({category, C}, Node1), true};
	       record_access ->
		 Argument = refac_syntax:record_access_argument(Node),
		 Type = refac_syntax:record_access_type(Node),
		 Field = refac_syntax:record_access_field(Node),
		 Argument1 = add_category(Argument, C),
		 Type1 = case Type of
			   none -> none;
			   _ -> add_category(Type, record_type)
			 end,
		 Field1 = add_category(Field, record_field),
		 Node1 = rewrite(Node, refac_syntax:record_access(Argument1, Type1, Field1)),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     record_expr ->
		 Argument = refac_syntax:record_expr_argument(Node),
		 Type = refac_syntax:record_expr_type(Node),
		 Fields = refac_syntax:record_expr_fields(Node),
		 Argument1 = case Argument of
			       none -> none;
			       _ -> add_category(Argument, C)
			     end,
		 Type1 = add_category(Type, record_type),
		 Fields1 = add_category(Fields, C),
		 Node1 = rewrite(Node, refac_syntax:record_expr(Argument1, Type1, Fields1)),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     record_index_expr ->
		 Type = refac_syntax:record_index_expr_type(Node),
		 Field = refac_syntax:record_index_expr_field(Node),
		 Type1 = add_category(Type, record_type),
		 Field1 = add_category(Field, C),
		 Node1 = rewrite(Node, refac_syntax:record_index_expr(Type1, Field1)),
		 {refac_syntax:add_ann({category, C}, Node1), true};
	     record_field ->
		 Name = refac_syntax:record_field_name(Node),
		 Name1 = add_category(Name, record_field),
		 Value = refac_syntax:record_field_value(Node),
		 Value1 = case Value of
			    none -> none;
			    _ -> add_category(Value, C)
			  end,
		 Node1 = rewrite(Node, refac_syntax:record_field(Name1, Value1)),
		 {refac_syntax:add_ann({category, record_field}, Node1), true};
	     generator ->
		 P = refac_syntax:generator_pattern(Node),
		 B = refac_syntax:generator_body(Node),
		 P1 = add_category(P, pattern),
		 B1 = add_category(B, expression),
		 Node1 = rewrite(Node, refac_syntax:generator(P1, B1)),
		 {refac_syntax:add_ann({category, generator}, Node1), true};
	     attribute ->
		 case refac_syntax:atom_value(refac_syntax:attribute_name(Node)) of
		   define ->
		       Name = refac_syntax:attribute_name(Node),
		       Args = refac_syntax:attribute_arguments(Node),
		       MacroHead = ghead("Refac_util:do_add_category:MacroHead", Args),
		       MacroBody = tl(Args),
		       MacroHead1 = case refac_syntax:type(MacroHead) of
				      application ->
					  Operator = add_category(refac_syntax:application_operator(MacroHead), macro_name),
					  Arguments = add_category(refac_syntax:application_arguments(MacroHead), attribute),
					  rewrite(MacroHead, refac_syntax:application(Operator, Arguments));
				      _ -> add_category(MacroHead, macro_name)
				    end,
		       MacroBody1 = add_category(MacroBody, attribute),
		       Node1 = rewrite(Node, refac_syntax:attribute(Name, [MacroHead1| MacroBody1])),
		       {refac_syntax:add_ann({category, attribute}, Node1), true};
		   _ -> {refac_syntax:add_ann({category, C}, Node), false}
		 end;
	     %% TO ADD: other cases such as fields. Refer to the Erlang Specification.
	     binary_field ->{refac_syntax:add_ann({category, binary_field}, Node), false};
	     size_qualifier ->{refac_syntax:add_ann({category, size_qualifier}, Node), false};
	     _ -> {refac_syntax:add_ann({category, C}, Node), false}
	   end
    end.



%%=================================================================
%% @doc Return true if the abstract syntax tree represented by Node has side effect, 
%%      otherwise return false. As to parameters, File represents filename of the
%%      code to which Node belongs,  Node is the abstract syntax tree representaion of 
%%      the syntax phrase of interest, and SearchPaths specifies the directories to 
%%      search for related local Erlang source files.
%% @spec has_side_effect(File::filename(), Node::syntaxTree(), SearchPaths::[dir()])-> true|false|unknown

%%-spec(has_side_effect(File::filename(), Node::syntaxTree(), SearchPaths::[dir()])-> true|false|unknown).
has_side_effect(_File, Node, _SearchPaths) ->
    LibSideEffectFile = list_to_atom(filename:join(?WRANGLER_DIR, "plt/side_effect_plt")),
    LibPlt = from_dets(lib_side_effect_plt, LibSideEffectFile),
    Res = check_side_effect(Node, LibPlt, none),
    case Res of
      true -> dets:close(LibSideEffectFile),
	      ets:delete(LibPlt),
	      true;
      false -> dets:close(LibSideEffectFile),
	       ets:delete(LibPlt),
	       false;
      unknown ->
	  dets:close(LibSideEffectFile),
	  ets:delete(LibPlt),
	  unknown
    end.
            %% The following is too slow for a large project.
	    %% CurrentDir = filename:dirname(normalise_file_name(File)),
	    %% LocalSideEffectFile = filename:join(CurrentDir, "local_side_effect_tab"),
	    %% build_local_side_effect_tab(LocalSideEffectFile, SearchPaths),
	    %% LocalPlt = from_dets(local_side_effect_plt, LocalSideEffectFile),
	    %% Res1 = check_side_effect(Node, LibPlt, LocalPlt),
	    %% dets:close(LibSideEffectFile),
	    %% dets:close(list_to_atom(LocalSideEffectFile)),
	    %% ets:delete(LocalPlt),
	    %% ets:delete(LibPlt),
	    %% Res1		



%%=================================================================
%% @spec build_local_side_effect_tab(File::filename(), SearchPaths::[dir()]) -> true.
%% @doc Build a local side effect table for File and the files contained in SearchPaths, and
%% put the result to the dets file: local_side_effect_tab. 
%%
%% @see build_lib_side_effect_tab/2.

%%-spec(build_local_side_effect_tab(File::filename(), SearchPaths::[dir()]) -> true).
build_local_side_effect_tab(File, SearchPaths) ->
    ValidSearchPaths = lists:all(fun (X) -> filelib:is_dir(X) end, SearchPaths),
    case ValidSearchPaths of
      true -> ok;
      false ->
	  throw("One of the directories sepecified in the search paths does not exist, please check the customization!")
    end,
    CurrentDir = filename:dirname(normalise_file_name(File)),
    SideEffectFile = filename:join(CurrentDir, "local_side_effect_tab"),
    LibSideEffectFile = filename:join(?WRANGLER_DIR, "plt/side_effect_plt"),
    LibPlt = from_dets(lib_side_effect_plt, LibSideEffectFile),
    Dirs = lists:usort([CurrentDir| SearchPaths]),
    Files = refac_util:expand_files(Dirs, ".erl"),
    SideEffectFileModifiedTime = filelib:last_modified(SideEffectFile),
    FilesToAnalyse = [F || F <- Files, SideEffectFileModifiedTime < filelib:last_modified(F)],
    LocalPlt = case filelib:is_file(SideEffectFile) of
		 true -> from_dets(local_side_effect_tab, SideEffectFile);
		 _ -> ets:new(local_side_effect_tab, [set, public])
	       end,
    #callgraph{callercallee = _CallerCallee, scc_order = Sccs, external_calls = _E} = wrangler_callgraph_server:build_scc_callgraph(FilesToAnalyse),
    build_side_effect_tab(Sccs, LocalPlt, LibPlt),
    to_dets(LocalPlt, SideEffectFile),
    dets:close(list_to_atom(LibSideEffectFile)),
    ets:delete(LocalPlt),
    ets:delete(LibPlt).


%%=================================================================
%% @spec build_lib_side_effect_tab(FileOrDirs::[fileName()|dir()]) -> true.
%% @doc Build the side effect table for Erlang libraries specified in FileOrDirs, and
%% put the result to the dets file: plt/side_effect_plt. 
%%
%% @see build_local_side_effect_tab/2.
%%-spec(build_lib_side_effect_tab([dir()]) -> true).
build_lib_side_effect_tab(SearchPaths) ->
    Plt = ets:new(side_effect_table, [set, public]),
    #callgraph{callercallee = _CallerCallee, scc_order = Sccs, external_calls = _E} = wrangler_callgraph_server:build_scc_callgraph(SearchPaths),
    build_side_effect_tab(Sccs, Plt, ets:new(dummy_tab, [set, public])),
    ets:insert(Plt, bifs_side_effect_table()),
    File = filename:join(?WRANGLER_DIR, "plt/side_effect_plt"),
    to_dets(Plt, File),
    ets:delete(Plt).

from_dets(Name, Dets) when is_atom(Name) ->
    Plt = ets:new(Name, [set, public]),
    case dets:open_file(Dets, [{access, read}]) of
      {ok, D} ->
	  true = ets:from_dets(Plt, D),
	  ok = dets:close(D),
	  Plt;
      {error, Reason} -> erlang:error(Reason)
    end.

to_dets(Plt, Dets) ->
    file:delete(Dets),
    MinSize = ets:info(Plt, size),
	{ok, DetsRef} = dets:open_file(Dets, [{min_no_slots, MinSize}]),
	ok = dets:from_ets(DetsRef, Plt),
    ok = dets:sync(DetsRef),
    ok = dets:close(DetsRef).

build_side_effect_tab([Scc | Left], Side_Effect_Tab, OtherTab) ->
    R = side_effect_scc(Scc, Side_Effect_Tab, OtherTab),
    true = ets:insert(Side_Effect_Tab,
		      [{{Mod, Fun, Arg}, R} || {{Mod, Fun, Arg}, _F} <- Scc]),
    build_side_effect_tab(Left, Side_Effect_Tab, OtherTab);
build_side_effect_tab([], Side_Effect_Tab, _) -> Side_Effect_Tab.

side_effect_scc([{{_M, _F, _A}, Def}, F | Left], Side_Effect_Tab, OtherTab) ->
    case check_side_effect(Def, Side_Effect_Tab, OtherTab) of
      true -> true;
      _ -> side_effect_scc([F | Left], Side_Effect_Tab, OtherTab)
    end;
side_effect_scc([{{_M, _F, _A}, Def}], Side_Effect_Tab, OtherTab) ->
    check_side_effect(Def, Side_Effect_Tab, OtherTab).


check_side_effect(Node, LibPlt, LocalPlt) ->
    LookUp=fun(MFA) ->
		   case lookup(LibPlt, MFA) of
		       {value, S} -> S;
		       _ ->
			   case LocalPlt of 
			       none -> unknown;
			       _ -> case lookup(LocalPlt, MFA) of
					{value, S} -> S;
					_ -> unknown
				    end			  
			   end
		   end
	   end,
    case refac_syntax:type(Node) of
	receive_expr -> true;
	infix_expr -> Op = refac_syntax:operator_literal(refac_syntax:infix_expr_operator(Node)), 
		      Op == "!";
	fun_expr -> false;
	implicit_fun -> false;
	application ->
	    Operator = refac_syntax:application_operator(Node),
	    Arity = length(refac_syntax:application_arguments(Node)),
	    case refac_syntax:type(Operator) of
		atom ->
		    Op = refac_syntax:atom_value(Operator),
		    {value, {fun_def, {M, _N, _A, _P1, _P}}} = lists:keysearch(fun_def, 1, refac_syntax:get_ann(Operator)),
		    LookUp({M,Op, Arity});
		module_qualifier ->
		    Mod = refac_syntax:module_qualifier_argument(Operator),
		    Body = refac_syntax:module_qualifier_body(Operator),
		    case {refac_syntax:type(Mod), refac_syntax:type(Body)} of
			{atom, atom} ->
			    M = refac_syntax:atom_value(Mod),
			    Op = refac_syntax:atom_value(Body),
			    LookUp({M, Op, Arity});
			_ -> unknown
		    end;
		_ -> unknown
	    end;
	arity_qualifier ->
	    Fun = refac_syntax:arity_qualifier_body(Node),
	    A = refac_syntax:arity_qualifier_argument(Node),
	    case {refac_syntax:type(Fun), refac_syntax:type(A)} of
		{atom, integer} ->
		    FunName = refac_syntax:atom_value(Fun),
		    Arity = refac_syntax:integer_value(A),
		    {value, {fun_def, {M, _N, _A, _P1, _P}}} = lists:keysearch(fun_def, 1, refac_syntax:get_ann(FunName)),
		    LookUp({M, FunName, Arity});
		_ -> unknown
	    end;
	atom -> false;
	_ ->
	    case refac_syntax:subtrees(Node) of
		[] -> false;
		Ts ->
		    Res = lists:flatten([[check_side_effect(T, LibPlt, LocalPlt) || T <- G] || G <- Ts]),
		    case lists:member(true, Res) of
			true -> true;
			false ->
			    case lists:member(unknown, Res) of
				true -> unknown;
				_ -> false
			    end
		    end
	    end
    end.

lookup(Plt, {M, F, A}) ->
    case ets:lookup(Plt, {M, F, A}) of
      [] -> none;
      [{_MFA, S}] -> {value, S}
    end.


%%====================================================================================
%%@spec build_callgraph(DirList::[dir()]) -> #callgraph{}
%%@doc Build a function call graph out of the Erlang files contained in the given directories.


%% =====================================================================
%% @spec bifs_side_effect_table()->[{{atom(), atom(), integer()}, boolean()}]
%% @doc The side effect table of BIFs.
%%-spec(bifs_side_effect_table()->[{{atom(), atom(), integer()}, boolean()}]).
bifs_side_effect_table() ->
    [{{erlang, abs, 1}, false}, {{erlang, append_element, 2}, false}, {{erlang, atom_to_list, 1}, false},
     {{erlang, binary_to_list, 1}, false}, {{erlang, binary_to_list, 3}, false}, {{erlang, binary_to_term, 1}, false},
     {{erlang, bump_reductions, 1}, false}, {{erlang, cancel_timer, 1}, true}, {{erlang, check_process_code, 1}, false},
     {{erlang, concat_binary, 1}, false}, {{erlang, data, 3}, false}, {{erlang, delete_module, 1}, true},
     {{erlang, demonitor, 1}, false}, {{erlang, disconnect_node, 1}, true}, {{erlang, display, 1}, true},
     {{erlang, element, 2}, false}, {{erlang, erase, 0}, true}, {{erlang, erase, 1}, true}, {{erlang, error, 1}, true},
     {{erlang, error, 2}, true}, {{erlang, exit, 1}, true}, {{erlang, exit, 2}, true}, {{erlang, fault, 1}, true},
     {{erlang, fault, 2}, true}, {{erlang, float, 1}, false}, {{erlang, float_to_list, 1}, false},
     {{erlang, fun_info, 2}, false}, {{erlang, fun_info, 1}, false}, {{erlang, fun_to_list, 1}, false},
     {{erlang, function_exported, 3}, true}, {{erlang, garbage_collect, 1}, true}, {{erlang, garbage_collect, 0}, true},
     {{erlang, get, 0}, true}, {{erlang, get, 1}, true}, {{erlang, get_cookie, 0}, true},{{erlang, get_keys, 1}, true},
     {{erlang, get_stacktrace, 0}, true}, {{erlang, group_leader, 0}, true}, {{erlang, group_leader, 2}, true},
     {{erlang, halt, 0}, true}, {{erlang, halt, 1}, true}, {{erlang, hash, 2}, false}, {{erlang, hd, 1}, false},
     {{erlang, hibernate, 3}, true}, {{erlang, info, 1}, true}, {{erlang, integer_to_list, 1}, false},
     {{erlang, iolist_to_binary, 1}, false}, {{erlang, iolist_size, 1}, false}, {{erlang, is_atom, 1}, false},
     {{erlang, is_binary, 1}, false}, {{erlang, is_boolean, 1}, false}, {{erlang, is_builtin, 3}, false},
     {{erlang, is_float, 1}, false}, {{erlang, is_function, 1}, false}, {{erlang, is_function, 2}, false},
     {{erlang, is_integer, 1}, false}, {{erlang, is_list, 1}, false}, {{erlang, is_number, 1}, false},
     {{erlang, is_pid, 1}, true}, {{erlang, is_port, 1}, false}, {{erlang, is_process_alive, 1}, true},
     {{erlang, is_record, 2}, false}, {{erlang, is_record, 3}, false}, {{erlang, is_reference, 1}, false},
     {{erlang, is_tuple, 1}, false}, {{erlang, length, 1}, false}, {{erlang, link, 1}, true},
     {{erlang, list_to_atom, 1}, false}, {{erlang, list_to_binary, 1}, false},
     {{erlang, list_to_existing_atom, 1}, false}, {{erlang, list_to_float, 1}, false},
     {{erlang, list_to_integer, 1}, false}, {{erlang, list_to_integer, 2}, false}, {{erlang, list_to_pid, 1}, false},
     {{erlang, list_to_tuple, 1}, false}, {{erlang, load_module, 2}, true}, {{erlang, loaded, 0}, true},
     {{erlang, localtime, 0}, true}, {{erlang, localtime_to_universaltime, 1}, false},
     {{erlang, localtime_to_iniversaltime, 2}, false}, {{erlang, make_ref, 0}, true}, {{erlang, make_tuple, 2}, true},
     {{erlang, md5, 1}, false}, {{erlang, md5_final, 1}, false}, {{erlang, md5_init, 0}, false},
     {{erlang, md5_update, 2}, false}, {{erlang, memory, 0}, true}, {{erlang, memory, 1}, true},
     {{erlang, module_loaded, 1}, true}, {{erlang, monitor, 2}, true}, {{erlang, monitor_node, 2}, true},
     {{erlang, node, 0}, true}, {{erlang, node, 1}, true}, {{erlang, nodes, 0}, true}, {{erlang, nodes, 1}, true},
     {{erlang, now, 0}, true}, {{erlang, open_port, 2}, true}, {{erlang, phash, 2}, false}, {{erlang, phash2, 2}, false},
     {{erlang, pid_to_list, 1}, true}, {{erlang, port_close, 1}, true}, {{erlang, port_command, 2}, true},
     {{erlang, port_connect, 2}, true}, {{erlang, port_control, 3}, true}, {{erlang, port_call, 3}, true},
     {{erlang, port_info, 1}, true}, {{erlang, port_info, 2}, true}, {{erlang, port_to_list, 1}, true},
     {{erlang, ports, 0}, true}, {{erlang, pre_loaded, 0}, true}, {{erlang, process_diaplay, 2}, true},
     {{erlang, process_flag, 2}, true}, {{erlang, process_flag, 3}, true}, {{erlang, process_info, 1}, true},
     {{erlang, process_info, 2}, true}, {{erlang, processes, 0}, true}, {{erlang, purge_module, 1}, true},
     {{erlang, put, 2}, true}, {{erlang, raise, 3}, true}, {{erlang, read_timer, 1}, true},
     {{erlang, ref_to_list, 1}, false}, {{erlang, register, 2}, true}, {{erlang, registered, 0}, true},
     {{erlang, resume_process, 1}, true}, {{erlang, round, 1}, false}, {{erlang, self, 0}, true},
     {{erlang, send, 2}, true}, {{erlang, send, 3}, true}, {{erlang, send_after, 3}, true},
     {{erlang, send_nosuspend, 2}, true}, {{erlang, send_nosuspend, 3}, true}, {{erlang, set_cookie, 2}, true},
     {{erlang, setelement, 3}, false}, {{erlang, size, 1}, false}, {{erlang, spawn, 1}, true}, {{erlang, spawn, 2}, true},
     {{erlang, spawn, 3}, true}, {{erlang, spawn, 4}, true}, {{erlang, spawn_link, 1}, true},
     {{erlang, spawn_link, 2}, true}, {{erlang, spawn_link, 3}, true}, {{erlang, spawn_link, 4}, true},
     {{erlang, spawn_opt, 2}, true}, {{erlang, spawn_opt, 3}, true}, {{erlang, spawn_opt, 4}, true},
     {{erlang, spawn_opt, 5}, true}, {{erlang, aplit_binary, 2}, false}, {{erlang, start_timer, 3}, true},
     {{erlang, statistics, 1}, true}, {{erlang, suspend_process, 1}, false}, {{erlang, system_flag, 2}, true},
     {{erlang, system_info, 1}, true}, {{erlang, system_monitor, 0}, true}, {{erlang, system_monitor, 1}, true},
     {{erlang, system_monitor, 2}, true}, {{erlang, term_to_binary, 1}, false}, {{erlang, term_to_binary, 2}, false},
     {{erlang, throw, 1}, true}, {{erlang, time, 1}, true}, {{erlang, tl, 1}, false}, {{erlang, trace, 1}, true},
     {{erlang, trace_info, 2}, true}, {{erlang, trace_pattern, 2}, true}, {{erlang, trace_pattern, 3}, true},
     {{erlang, trunc, 1}, false}, {{erlang, unregister, 1}, false}, {{erlang, unregister, 1}, true},
     {{erlang, tuple_to_list, 1}, false}, {{erlang, universaltime, 1}, false},
     {{erlang, universaltime_to_localtime, 1}, false}, {{erlang, unlink, 1}, true}, {{erlang, whereis, 1}, true},
     {{erlang, yield, 1}, true}].


%% =====================================================================
%% @spec auto_imported_bifs()->[{atom(), integer()}]
%% @doc The list of automatically imported BIFs.

%%-spec(auto_imported_bifs()->[{atom(), atom(), integer()}]).
auto_imported_bifs() ->
    [{erlang, abs, 1},   {erlang, adler32,1}, {erlang, adler32, 2},  {erlang, adler32_combine, 3}, {erlang, atom_to_binary, 2},    
     {erlang, apply, 2}, {erlang, apply, 3}, {erlang, atom_to_list, 1}, 
     {erlang, binary_to_atom, 2}, {erlang, binary_to_list, 1}, {erlang, binary_to_list, 3}, {erlang, binary_to_term, 1}, 
     {erlang, check_process_code, 2},
     {erlang, concat_binary, 1},  {erlang, date, 0},          {erlang, delete_module, 1}, {erlang, disconnect_node, 1},
     {erlang, element, 2},        {erlang, erase, 0},          {erlang, erase, 1}, {erlang, exit, 1}, {erlang, exit, 2}, {erlang, float, 1},
     {erlang, float_to_list, 1},  {erlang, garbage_collect, 1},{erlang, garbage_collect, 0}, {erlang, get, 0},
     {erlang, get, 1},            {erlang, get_keys, 1},       {erlang, group_leader, 0}, {erlang, group_leader, 2}, {erlang, halt, 0},
     {erlang, halt, 1},           {erlang, hd, 1},             {erlang, integer_to_list, 1}, {erlang, iolist_to_binary, 1},
     {erlang, iolist_size, 1},    {erlang, is_atom, 1},        {erlang, is_binary, 1}, {erlang, is_boolean, 1},
     {erlang, is_float, 1},       {erlang, is_function, 1},    {erlang, is_function, 2}, {erlang, is_integer, 1},
     {erlang, is_list, 1},        {erlang, is_number, 1},      {erlang, is_pid, 1}, {erlang, is_port, 1},
     {erlang, is_process_alive,1},{erlang, is_record, 2},      {erlang, is_record, 3}, {erlang, is_reference, 1},
     {erlang, is_tuple, 1},       {erlang, length, 1},         {erlang, link, 1}, {erlang, list_to_atom, 1},
     {erlang, list_to_binary, 1}, {erlang, list_to_existing_atom, 1}, {erlang, list_to_float, 1},
     {erlang, list_to_integer, 1},{erlang, list_to_pid, 1},    {erlang, list_to_tuple, 1},
     {erlang, load_module, 2},    {erlang, make_ref, 0},       {erlang, module_loaded, 1}, {erlang, monitor_node, 2},
     {erlang, node, 0},           {erlang, node, 1},           {erlang, nodes, 0}, {erlang, nodes, 1}, {erlang, now, 0}, {erlang, open_port, 2},
     {erlang, pid_to_list, 1},    {erlang, port_close, 1},     {erlang,  port_command, 2}, {erlang,  port_connect, 2},
     {erlang,  port_control, 3},  {erlang,  pre_loaded, 0},    {erlang, process_flag, 2}, {erlang, process_flag, 3},
     {erlang, process_info, 1},   {erlang, process_info, 2},   {erlang, processes, 0}, {erlang, purge_module, 1},
     {erlang, put, 2},            {erlang, register, 2},       {erlang, registered, 0}, {erlang, round, 1}, {erlang, self, 0},
     {erlang, setelement, 3},     {erlang, size, 1},           {erlang, spawn, 1}, {erlang, spawn, 2}, {erlang, spawn, 3},
     {erlang, spawn, 4},          {erlang, spawn_link, 1},     {erlang, spawn_link, 2}, {erlang, spawn_link, 3},
     {erlang, spawn_link, 4},     {erlang, spawn_opt, 2},      {erlang, spawn_opt, 3}, {erlang, spawn_opt, 4},
     {erlang, spawn_opt, 5},      {erlang, aplit_binary, 2},   {erlang, statistics, 1}, {erlang, term_to_binary, 1},
     {erlang, term_to_binary, 2}, {erlang, throw, 1},          {erlang, time, 1}, {erlang, tl, 1}, {erlang, trunc, 1},
     {erlang, unregister, 1},     {erlang, unregister, 1},     {erlang, tuple_to_list, 1}, {erlang, unlink, 1},
     {erlang, whereis, 1}].


%% =====================================================================
%% @spec callback_funs(Behaviour)->[{FunName, Arity}]
%%       Behaviour = gen_server | gen_event | gen_fsm | supervisor
%%       FunName = atom()
%%       Arity = integer()
%% @doc Pre-defined callback functions by the standard Erlang behaviours.

%%-type(behaviour()::gen_server | gen_event | gen_fsm | supervisor).
%%-spec(callback_funs(behaviour())->[{atom(), integer()}]).
callback_funs(Behaviour) ->
    case Behaviour of
      gen_server ->
	  [{init, 1}, {handle_call, 3}, {handle_cast, 2}, {handle_info, 2},
	   {terminate, 2}, {code_change, 3}];
      gen_event ->
	  [{init, 1}, {handle_event, 2}, {handle_call, 2}, {handle_info, 2},
	   {terminate, 2}, {code_change, 3}];
      gen_fsm ->
	  [{init, 1}, {handle_event, 3}, {handle_sync_event, 4}, {handle_info, 3},
	   {terminate, 3}, {code_change, 4}];
      supervisor -> [{init, 1}];
      _ -> []
    end.


test_framework_used(FileName) ->
    case refac_epp_dodger:parse_file(FileName, []) of
      {ok, Forms} ->
	  Strs = lists:flatmap(fun (F) ->
				       case refac_syntax:type(F) of
					 attribute ->
					     Name = refac_syntax:attribute_name(F),
					     Args = refac_syntax:attribute_arguments(F),
					     case refac_syntax:type(Name) of
					       atom ->
						   AName = refac_syntax:atom_value(Name),
						   case AName == include orelse AName == include_lib of
						     true ->
							 lists:flatmap(fun (A) -> case A of
										    {string, _, Str} -> [Str];
										    _ -> []
										  end
								       end, Args);
						     _ -> []
						   end;
					       _ -> []
					     end;
					 _ -> []
				       end
			       end, Forms),
	  Eunit = lists:any(fun (S) -> lists:suffix("eunit.hrl", S) end, Strs),
	  EQC = lists:any(fun (S) -> lists:suffix("eqc.hrl", S) end, Strs),
	  EQC_STATEM = lists:any(fun (S) -> lists:suffix("eqc_statem.hrl", S) end, Strs),
	  EQC_FSM = lists:any(fun (S) -> lists:suffix("eqc_fsm.hrl", S) end, Strs),
	  TestSever = lists:suffix(FileName, "_SUITE.erl") and
			lists:any(fun (S) -> lists:suffix("test_server.hrl", S) end, Strs),
	  CommonTest = lists:suffix(FileName, "_SUITE.erl") and
			 lists:any(fun (S) -> lists:suffix("ct.hrl", S) end, Strs),
	  lists:flatmap(fun ({F, V}) -> case V of
					  true -> [F];
					  _ -> []
					end
			end, [{eunit, Eunit}, {eqc, EQC}, {eqc_statem, EQC_STATEM},
			      {eqc_fsm, EQC_FSM},
			      {testserver, TestSever}, {commontest, CommonTest}]);
      _ -> []
    end.
   
    
	
is_whitespace_or_comment({whitespace, _, _}) ->
    true;
is_whitespace_or_comment({comment, _, _}) ->
    true;
is_whitespace_or_comment(_) -> false.
	
    
is_string({string, _, _}) ->
    true;
is_string(_) -> false.

file_format(File) ->  
    {ok, Bin} = file:read_file(File),
    S = erlang:binary_to_list(Bin),
    LEs = scan_line_endings(S),
    case LEs of 
	[] -> unix;    %% default fileformat;
	_ ->  case lists:all(fun(E) -> E=="\r\n" end, LEs) of 
		  true -> dos;
		  _ -> case lists:all(fun(E) -> E=="\r" end, LEs)  of
			   true ->
			       mac;
			   _ -> case lists:all(fun(E)-> E=="\n" end, LEs) of
				    true -> unix;
				    _ -> throw({error, File ++ " uses a mixture of line endings,"
						" please normalise it to one of the standard file "
						"formats (i.e. unix/dos/mac) before performing any refactorings."})
				end
		       end
	      end
    end.

scan_line_endings(Cs)->
    scan_lines(Cs, [], []).

scan_lines([$\r|Cs], [], Acc) ->
    scan_line_endings(Cs, [$\r], Acc);
scan_lines([$\n|Cs], [], Acc) ->
    scan_lines(Cs, [], [[$\n]|Acc]);
scan_lines([_C|Cs], [], Acc) ->
    scan_lines(Cs, [], Acc);
scan_lines([],[],Acc) ->
    Acc.

scan_line_endings([$\r|Cs], Cs1,Acc) ->
    scan_line_endings(Cs,[$\r|Cs1], Acc);
scan_line_endings([$\n|Cs], Cs1, Acc) ->
    scan_lines(Cs, [],[lists:reverse([$\n|Cs1])| Acc]);
scan_line_endings([_C|Cs], Cs1, Acc)->
    scan_lines(Cs, [], [lists:usort(lists:reverse(Cs1))|Acc]);
scan_line_endings([], Cs1, Acc)->
    lists:reverse([lists:usort(lists:reverse(Cs1))|Acc]).
    

%% check why this is needed.
remove_duplicates(L) ->
    remove_duplicates(L, []).
remove_duplicates([],Acc) ->
     lists:reverse(Acc);
remove_duplicates([H|T], Acc) ->
    case lists:member(H, Acc) of
	true ->
	    remove_duplicates(T, Acc);
	_ ->
	    remove_duplicates(T, [H|Acc])
    end.

rewrite(Tree, Tree1) ->
    refac_syntax:copy_attrs(Tree, Tree1).
 
format_search_paths(Paths) ->
    format_search_paths(Paths, "").
    
format_search_paths([], Str)->
    Str;
format_search_paths([P|T], Str)->
    case Str of
	[] ->format_search_paths(T, "\""++P++"\"");
	_ ->format_search_paths(T, Str++", \""++P++"\"")
    end.

predefined_macros() ->
    ['MODULE', 'MODULE_STRING', 'FILE', 'LINE', 'MACHINE'].
    
default_incls() ->
  [".", "..", "../hrl", "../incl", "../inc", "../include",
   "../../hrl", "../../incl", "../../inc", "../../include",
   "../../../hrl", "../../../incl", "../../../inc", "../../../include"].

%%-spec(concat_toks(Toks::[token()]) ->string()).
concat_toks(Toks) ->
    concat_toks(Toks, "").

concat_toks([], Acc) ->
     lists:concat(lists:reverse(Acc));
concat_toks([T|Ts], Acc) ->
     case T of 
	 {atom, _,  V} -> S = io_lib:write_atom(V), 
			  concat_toks(Ts, [S|Acc]);
	 {qatom, _, V} -> S=atom_to_list(V),
			  concat_toks(Ts, [S|Acc]);
	 {string, _, V} -> concat_toks(Ts,["\"", V, "\""|Acc]);
	 {char, _, V} when is_integer(V) and (V =< 127)-> concat_toks(Ts,[io_lib:write_char(V)|Acc]);
	 {char, _, V} when is_integer(V) ->
	     {ok, [Num], _} = io_lib:fread("~u", integer_to_list(V)),
	     [Str] = io_lib:fwrite("~.8B", [Num]),
	     S = "$\\"++Str,
	     concat_toks(Ts, [S|Acc]); 
	 {float, _, V} -> concat_toks(Ts,[io_lib:write(V)|Acc]);
	 {_, _, V} -> concat_toks(Ts, [V|Acc]);
	 {dot, _} ->concat_toks(Ts, ['.'|Acc]);
	 {V, _} -> 
	     concat_toks(Ts, [V|Acc])
     end.
