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
%% ============================================================================================
%% Refactoring: Instrument the program to trace process communication information.
%%
%% Author contact: hl@kent.ac.uk, sjt@kent.ac.uk
%% 
%% =============================================================================================

%% =============================================================================================
-module(refac_instrument).

-export([instrument_prog/3, uninstrument_prog/3]).

-include("../include/wrangler.hrl").
%% =============================================================================================
%% @spec intrument_prog(FileName::filename(), SearchPaths::[filename()])-> term()
%%         

%%-spec(instrument_prog/3::(filename(), [dir()], integer()) ->{ok, [filename()]} | {error, string()}).      
instrument_prog(FileName,SearchPaths, TabWidth)-> 
 
   instrument_prog(FileName, SearchPaths, wrangler, trace_send, 4, TabWidth).

instrument_prog(FileName, SearchPaths, ModName, FunName, Arity, TabWidth) ->
    ?wrangler_io("\n[CMD: instrument_prog, ~p, ~p]\n", [FileName, SearchPaths]),
    CurrentDir = filename:dirname(normalise_file_name(FileName)),
    TraceCacheFile = filename:join(CurrentDir, "wrangler_trace_cache"),
    Dirs = lists:usort([CurrentDir|SearchPaths]),
    Files = refac_util:expand_files(Dirs, ".erl"),
    case  instrument_files(Files, {ModName, FunName, Arity}, TraceCacheFile, SearchPaths, TabWidth) of 
	InstrumentedFiles ->
	    refac_util:write_refactored_files(InstrumentedFiles),
	    ChangedFiles = lists:map(fun({{F, _}, _AST}) -> F end, InstrumentedFiles),
	    case ChangedFiles of 
		[] -> ?wrangler_io("No files were changed by this refactoring\n", []);
		_ ->  ?wrangler_io("The following files have been changed by this refactoring:\n~p\n",
				[ChangedFiles])
	    end,	      
	    {ok,ChangedFiles}
    end.
	

instrument_files([F|Fs], {ModName,FunName, Arity}, TraceCacheFile,SearchPaths, TabWidth) ->
    {ok, {AnnAST, Info}} = refac_util:parse_annotate_file(F,true, SearchPaths, TabWidth ),
    {ok, CurrentModName} = get_module_name(Info),
    {AnnAST1, Modified} = refac_util:stop_tdTP(fun do_instrument/2, AnnAST,{TraceCacheFile, CurrentModName, {ModName, FunName, Arity}}),
    if Modified ->
	    [{{F, F}, AnnAST1} | instrument_files(Fs, {ModName, FunName, Arity},TraceCacheFile,  SearchPaths, TabWidth)];
       true -> 
	    instrument_files(Fs, {ModName, FunName, Arity}, TraceCacheFile, SearchPaths, TabWidth)
    end;	       
instrument_files([], _, _, _, _) ->
    [].

do_instrument(Tree, {TraceCacheFile, CurrentModName,{ModName, FunName, Arity}}) ->
    case refac_syntax:type(Tree) of 
	function -> 
	    CurrentModName1 = refac_syntax:atom(CurrentModName),
	    CurrentFunArity = refac_syntax:integer(refac_syntax:function_arity(Tree)),
            CurrentFunName = refac_syntax:function_name(Tree),
	    Pid = start_counter_process(),
	    {Tree1, _} = refac_util:stop_tdTP(fun do_uninstrument/2, Tree, {ModName, FunName, Arity}),
            Res = refac_util:stop_tdTP(fun do_instrument_in_fun/2, Tree1, 
				       {ModName, FunName, Arity, CurrentModName1, CurrentFunName, CurrentFunArity, Pid, TraceCacheFile}),
	    Pid ! stop,
	    Res;
	_ -> {Tree, false}
    end.

do_instrument_in_fun(Tree, {ModName, FunName, _Arity, CurrentModName, CurrentFunName, CurrentFunArity, Pid, TraceCacheFile}) ->
    case refac_syntax:type(Tree) of 
	infix_expr ->
	     case is_send_expr(Tree) of 
		 true ->  Pid ! {self(), next},
			  receive 
			      {Pid, N} -> N
			  end,
			  ReceiverPid = refac_syntax:infix_expr_left(Tree),
                          FunCall=refac_syntax:application(refac_syntax:module_qualifier(refac_syntax:atom(ModName),refac_syntax:atom(FunName)), 
							  [refac_syntax:tuple([CurrentModName,CurrentFunName, CurrentFunArity]), 
							   refac_syntax:integer(N), ReceiverPid,refac_syntax:atom( TraceCacheFile)]),
			 {refac_syntax:block_expr([FunCall, Tree]), true};
		 _ -> {Tree, false}
	     end;
	_ -> {Tree, false}
    end.


	        
	

is_send_expr(Tree) ->
    case refac_syntax:type(Tree) of 
	infix_expr ->
	    Op = refac_syntax:infix_expr_operator(Tree),
	    case refac_syntax:type(Op) of 
		operator ->
		    refac_syntax:operator_name(Op) == '!';
		_ -> false
	    end;
	_ -> false
    end.
    

normalise_file_name(Filename) ->
    filename:join(filename:split(Filename)).

start_counter_process() ->
     spawn_link(fun()->loop(1) end).

loop(N) ->
    receive
	{From, next} ->
	    From ! {self(), N},
	    loop(N+1);
	stop ->
	    ok
    end.
	    

%%-spec(uninstrument_prog/3::(filename(), [dir()], integer()) ->{ok, [filename()]} | {error, string()}).
uninstrument_prog(FileName,SearchPaths, TabWidth)-> 
    uninstrument_prog(FileName, SearchPaths, wrangler, trace_send, 4, TabWidth).

uninstrument_prog(FileName, SearchPaths, ModName, FunName, Arity, TabWidth) ->
    ?wrangler_io("\n[CMD: uninstrument_prog, ~p, ~p]\n", [FileName, SearchPaths]),
    CurrentDir = filename:dirname(normalise_file_name(FileName)),
    Dirs = lists:usort([CurrentDir|SearchPaths]),
    Files = refac_util:expand_files(Dirs, ".erl"),
    case uninstrument_files(Files, {ModName, FunName, Arity}, SearchPaths, TabWidth) of
	UnInstrumentedFiles ->
	    refac_util:write_refactored_files(UnInstrumentedFiles),
	    ChangedFiles = lists:map(fun({{F, _}, _AST}) -> F end, UnInstrumentedFiles),
	    case ChangedFiles of 
		[] -> ?wrangler_io("No files were changed by this refactoring\n",[]);
		_  ->  ?wrangler_io("The following files have been changed by this refactoring:\n~p\n",
				 [ChangedFiles])
	    end,
	    {ok,ChangedFiles}
    end.
    


uninstrument_files([F|Fs], {ModName,FunName, Arity}, SearchPaths, TabWidth) ->
    {ok, {AnnAST, _Info}} = refac_util:parse_annotate_file(F,true, SearchPaths, TabWidth),
    {AnnAST1, Modified} = refac_util:stop_tdTP(fun do_uninstrument/2, AnnAST, {ModName, FunName, Arity}),
    if Modified ->
	    [{{F, F}, AnnAST1} | uninstrument_files(Fs, {ModName, FunName, Arity}, SearchPaths, TabWidth)];
       true -> 
	    uninstrument_files(Fs, {ModName, FunName, Arity}, SearchPaths, TabWidth)
    end;	       
uninstrument_files([], _, _, _) ->
    [].


do_uninstrument(Tree, {ModName, FunName, Arity}) ->
    case refac_syntax:type(Tree) of
      block_expr ->
	  Es = refac_syntax:block_expr_body(Tree),
	  case length(Es) of
	    2 -> FstExp = hd(Es),
		 SndExp = lists:last(Es),
		 case {refac_syntax:type(FstExp), is_send_expr(SndExp)} of
		   {application, true} ->
		       case refac_move_fun:application_info(FstExp) of
			 {{ModName, FunName}, Arity} ->
			     {SndExp, true};
			 _ -> {Tree, false}
		       end;
		   _ -> {Tree, false}
		 end;
	    _ -> {Tree, false}
	  end;
      _ -> {Tree, false}
    end.

get_module_name(ModInfo) ->				      
    case lists:keysearch(module, 1, ModInfo) of
	{value, {module, ModName}} -> {ok, ModName};
	false ->
	    {error, "Can not get the current module name."}
    end.



