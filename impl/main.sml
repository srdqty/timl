structure RecurExamples = struct
open TypeCheck

infix  3 <\     fun x <\ f = fn y => f (x, y)     (* Left section      *)
infix  3 \>     fun f \> y = f y                  (* Left application  *)
infixr 3 />     fun f /> y = fn x => f (x, y)     (* Right section     *)
infixr 3 </     fun x </ f = f x                  (* Right application *)

infix  2 o  
infix  0 :=

infix  1 >|     val op>| = op</      (* Left pipe *)
infixr 1 |<     val op|< = op\>      (* Right pipe *)

infix 7 $
infix 6 %+
infix 6 %*
infix 4 %<=
infix 3 /\
infix 1 -->
infix 1 <->

fun ilist_left l = ExI ((Subset (BSUnit, "_", Eq (Time, T0, shift_i_i l))), "_", Unit)
fun ilist_right ilist t l = ExI ((Subset (Time, "l'", Eq (Time, VarI 0 %+ T1, shift_i_i l))), "l'", Prod (shift_i_t t, ilist [VarI 0]))
fun ilist_core t i = ("ilist", [("l", STime)],
		      Sum (ilist_left (VarI 0),
			   ilist_right (curry AppVar 0) (shift_t_t t) (VarI 0)), i)
fun ilist t i = AppRecur (ilist_core t i)
fun nil_ t = Fold (ilist t [T0], Inl (ilist_right (ilist t) t T0, Pack (ilist_left T0, Type.TT, TT)))
fun cons_ t (n : idx) x xs = Fold (ilist t [n %+ T1], Inr (ilist_left (n %+ T1), Pack (ilist_right (ilist t) t (n %+ T1), n, Pair (x, xs))))
(* val output = check [("n", STime)] [("a", Type)] [] (cons_ (VarT 0) (VarI 0)) *)
fun match_list e t d e1 iname ename e2 = SumCase (Unfold e, "_", Unpack (Var 0, t, d, "_", "_", shiftx_e_e 0 2 e1), "_", Unpack (Var 0, t, d, iname, ename, shiftx_e_e 1 1 e2))
fun map_ a b = AbsI (STime, "m", Abs (Arrow (shift_i_t a, VarI 0, shift_i_t b), "f", Fix (UniI (STime, "n", Arrow (ilist (shiftx_i_t 0 2 a) [VarI 0], (VarI 1 %+ Tconst 2) %* VarI 0, ilist (shiftx_i_t 0 2 b) [VarI 0])), "map", AbsI (STime, "n", Abs (ilist (shiftx_i_t 0 2 a) [VarI 0], "ls", match_list (Var 0) (ilist (shiftx_i_t 0 2 b) [VarI 0]) ((VarI 1 %+ Tconst 2) %* VarI 0) (nil_ (shiftx_i_t 0 2 b)) "n'" "x_xs" (cons_ (shiftx_i_t 0 2 b) (VarI 0) (App (Var 3, Fst (Var 0))) (App (AppI (Var 2, VarI 0), Snd (Var 0)))))))))
fun main () = check (([], []), [("b", Type), ("a", Type)], [], []) (map_ (VarT 1) (VarT 0))
(* val output = str_t (["l"], ["ilist"]) (ExI ((Subset (BSUnit, "nouse2", Eq (Time, VarI 1, T0))), "nouse1", Unit)) *)
(* val output = str_t (["l"], ["a", "ilist"]) (Sum (ExI ((Subset (BSUnit, "nouse2", Eq (Time, VarI 1, T0))), "nouse1", Unit), *)
(* 						 ExI ((Subset (Time, "l'", Eq (Time, VarI 1, VarI 0 %+ T1))), "l'", Prod (shift_t_t (VarT 0), AppVar (0, [VarI 0]))))) *)
(* val ilist1 = ilist (VarT 0) [VarI 0] *)
(* val output = str_t (["n"], ["a"]) ilist1 *)

(* val plus = Abs (Int, "a", Abs (Int, "b", Plus (Var 1, Var 0))) *)
(* val output = str_e (([], []), []) plus *)
(* val plus1 = Abs (Int, "a", Abs (Int, "b", Plus (Plus (Var 1, Var 0), Var 2))) *)
(* val output = str_e (([], []), ["c"]) plus1 *)
(* val ttt = Uni ("a", Uni ("b", Prod (Prod (VarT 1, VarT 0), VarT 2))) *)
(* val output = str_t ([], ["c"]) ttt *)
(* val output = str_t ([], []) (subst_t_t Int ttt) *)

(* val bool = Sum (Unit, Unit) *)
(* fun cmp_t t n = Arrow (t, T0, Arrow (t, n, bool)) *)
(* val msort = AbsT ("a", AbsI (STime, "m", Abs (cmp_t (VarT 0) (VarI 0), "cmp", AbsI (STime, "n", Fix (ilist (VarT 0) [VarI 0], VarI 1 %+ VarI 0, ilist (VarT 0) [VarI 0], "msort", "xs", nil_ (VarT 0)))))) *)
(* val empty = (([], []), []) *)
(* val output = str_e empty msort *)
(* val output = check [] [] [] msort *)

(* val plus_5_7 = App (App (plus, Const 5), Const 7) *)
(* (* val output = check [] [] [] plus_5_7 *) *)

(* val ilist1_core = ilist_core (VarT 0) [VarI 0 %+ T1] *)
(* val output = str_t (["n"], ["a"]) (unroll ilist1_core) *)

end

structure DatatypeExamples = struct
open TypeCheck

infix 7 $
infix 6 %+
infix 6 %*
infix 4 %<=
infix 3 /\
infix 1 -->
infix 1 <->

val ilist = KArrowDatatype (1, [STime])
fun NilI family = (family, ["a"], [], Unit, [T0])
fun ConsI family = (family, ["a"], [("n", STime)], Prod (VarT 0, AppDatatype (shiftx_v 0 1 family, [VarT 0], [VarI 0])), [VarI 0 %+ T1])
val ctx : context = (([], []), [("ilist", ilist)], [("ConsI", ConsI 0), ("NilI", NilI 0)], []) 
val NilI_int = AppConstr (1, [Int], [], TT)
val ConsI_int = AppConstr (0, [Int], [T0], Pair (Const 77, NilI_int))
fun main () = check ctx NilI_int
fun main () = check ctx ConsI_int

val map_ = 
    AbsT ("'a",
	  AbsT ("'b",
		AbsI (STime, "m", 
		      Abs (Arrow (VarT 1, VarI 0, VarT 0), "f", 
			   Fix (UniI (STime, "n", Arrow (AppDatatype (2, [VarT 1], [VarI 0]), (VarI 1 %+ Tconst 2) %* VarI 0, AppDatatype (2, [VarT 0], [VarI 0]))), "map", 
				AbsI (STime, "n", 
				      Abs (AppDatatype (2, [VarT 1], [VarI 0]), "ls", 
					   Case (Var 0, AppDatatype (2, [VarT 0], [VarI 0]), (VarI 1 %+ Tconst 2) %* VarI 0, 
						 [(Constr (1, [], "_"), AppConstr (1, [VarT 0], [], TT)),
						  (Constr (0, ["n'"], "x_xs"), AppConstr (0, [VarT 0], [VarI 0], Pair (App (Var 3, Fst (Var 0)), App (AppI (Var 2, VarI 0), Snd (Var 0)))))]))))))))

val wrong = AppConstr (1, [Int], [T0], Pair (Const 77, NilI_int))

fun main () =
    check ctx wrong ^ "\n" ^
    check ctx map_

end

structure NamefulDatatypeExamples = struct

structure T = NamefulType
structure E = NamefulExpr
open T
open E

infix 7 $
infix 6 %+
infix 6 %*
infix 4 %<=
infix 3 /\
infix 1 -->
infix 1 <->

val ilist = KArrowDatatype (1, [STime])
fun NilI family = (family, ["a"], [], Unit, [T0])
fun ConsI family = (family, ["a"], [("n", STime)], Prod (VarT "a", AppDatatype (family, [VarT "a"], [VarI "n"])), [VarI "n" %+ T1])
val NilI_int = AppConstr ("NilI", [Int], [], TT)
val ConsI_int = AppConstr ("ConsI", [Int], [T0], Pair (Const 77, NilI_int))

(*

map = fn a b (m :: Time) (f : a -- m -> b) 
        fix (map : forall n :: Time, list a n -- (m + 2) * n -> list b n) (n :: Time) (ls : list a n) =>
          case ls return list b n |> (m + 2) * n of
              NilI _ => NilI [b] ()
            | ConsI n' x_xs => ConsI [b] [n'] (f (fst x_xs), map [n'] (snd x_xs))

*)
			  
val map_ = 
    AbsT ("a",
	  AbsT ("b",
		AbsI (STime, "m", 
		      Abs (Arrow (VarT "a", VarI "m", VarT "b"), "f", 
			   Fix (UniI (STime, "n", Arrow (AppDatatype ("ilist", [VarT "a"], [VarI "n"]), (VarI "m" %+ Tconst 2) %* VarI "n", AppDatatype ("ilist", [VarT "b"], [VarI "n"]))), "map", 
				AbsI (STime, "n", 
				      Abs (AppDatatype ("ilist", [VarT "a"], [VarI "n"]), "ls", 
					   Case (Var "ls", AppDatatype ("ilist", [VarT "b"], [VarI "n"]), (VarI "m" %+ Tconst 2) %* VarI "n", 
						 [(Constr ("NilI", [], "_"), AppConstr ("NilI", [VarT "b"], [], TT)),
						  (Constr ("ConsI", ["n'"], "x_xs"), AppConstr ("ConsI", [VarT "b"], [VarI "n'"], Pair (App (Var "f", Fst (Var "x_xs")), App (AppI (Var "map", VarI "n'"), Snd (Var "x_xs")))))]))))))))

val wrong = AppConstr ("NilI", [Int], [T0], Pair (Const 77, NilI_int))

open Type
open Expr
open NameResolve
open TypeCheck

exception Resolve of string
fun try r = 
    case r of 
	OK v => v 
      | Failed msg => raise Resolve msg

(* fun main () = check ctx NilI_int *)
(* fun main () = check ctx ConsI_int *)
fun main () =
    let
	val sctx = ([], [])
	val sctxn = sctx_names sctx
	val ilist = (try o resolve_kind sctxn) ilist
	val skctx as (_, kctx) = (sctx, [("ilist", ilist)])
	val skctxn as (_, kctxn) = (sctxn, names kctx)
	val NilI = (try o resolve_constr skctxn) (NilI "ilist")
	val ConsI = (try o resolve_constr skctxn) (ConsI "ilist")
	val ctx as (_, _, cctx, tctx) : context = (sctx, kctx, [("ConsI", ConsI), ("NilI", NilI)], [])
	val ctxn = (sctxn, kctxn, names cctx, names tctx)
	val wrong = (try o resolve_expr ctxn) wrong
	val map_ = (try o resolve_expr ctxn) map_
    in
	check ctx wrong ^ "\n" ^
	check ctx map_
    end
    handle 
    Resolve msg => sprintf "Failed to resolve variable: $\n" [msg]

end

structure TestParser = struct
open Util
open Parser

fun main filename =
  let
      val src = ref (
	      "      map = fn [a] [b] {m : Time} (f : a -- m -> b) =>  " ^
	      "        fix (map : forall {n : Time}, list a {n} -- (m + 2) * n -> list b {n}) {n : Time} (ls : list a {n}) => " ^
	      "          case ls return list b {n} |> (m + 2) * n of  " ^
	      "              NilI _ => NilI [b] ()  " ^
	      "            | ConsI {n'} x_xs => ConsI [b] {n'} (f (fst x_xs), map {n'} (snd x_xs))  "
	  )

      val src = ref ")"
	      
      fun input _ = let val s = !src in src := ""; s end
      (* val filename = "string" *)

      (* val filename = "test.timl" *)
      val inStream =  TextIO.openIn filename
      fun input n =
	if TextIO.endOfStream inStream
	then ""
	else TextIO.inputN (inStream,n);

      fun str_pos (pos : pos) = sprintf "$.$" [str_int (#line pos), str_int (#col pos)]
      fun on_error (msg, left : pos, right) = print (sprintf "Error: $ $.\n  $\n" [filename, str_pos left, msg])
      val s = case parse_opt (input, on_error, on_error) of OK e => "" | Failed msg =>  msg
      val _ = TextIO.closeIn inStream
  in
      s
  end
  handle IO.Io e => sprintf "Error calling $ on file $\n" [#function e, #name e]
					      
end

structure Main = struct
fun main (prog_name, args : string list) : int = 
    let
	val output = ""
	(* val output = RecurExamples.main () *)
	(* val output = DatatypeExamples.main () *)
	(* val output = NamefulDatatypeExamples.main () *)
	val output = 
	    case args of
		filename :: _ => (TestParser.main filename; "")
	      | _ => "Usage: filename"
    in	
	print (output ^ "\n");
	0
    end
end

