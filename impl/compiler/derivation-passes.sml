structure DerivationPasses =
struct
  open MicroTiML
  open Util

  structure TypingDerivationShift =
  struct
    structure TypingDerivationShiftHelper =
    struct
      type down = int * context
      type up = unit

      val upward_base = ()
      fun combiner ((), ()) = ()

      fun shift_context_above delta dep ctx =
        let
          val (left, right) = List.splitAt (ctx, dep)
        in
          List.concat [left, delta, right]
        end

      fun on_typing_relation ((ctx, tm, ty, ti), (dep, delta)) =
        let
          val ctx' = shift_context_above delta dep ctx
          val tm' = Passes.TermShift.shift_term_above (List.length delta) dep tm
          val ty' = Passes.TermShift.shift_constr_above (List.length delta) dep ty
          val ti' = Passes.TermShift.shift_constr_above (List.length delta) dep ti
        in
          (ctx', tm', ty', ti')
        end

      fun on_kinding_relation ((ctx, cstr, kd), (dep, delta)) =
        let
          val ctx' = shift_context_above delta dep ctx
          val cstr' = Passes.TermShift.shift_constr_above (List.length delta) dep cstr
          val kd' = Passes.TermShift.shift_kind_above (List.length delta) dep kd
        in
          (ctx', cstr', kd')
        end

      fun on_proping_relation ((ctx, pr), (dep, delta)) =
        let
          val ctx' = shift_context_above delta dep ctx
          val pr' = Passes.TermShift.shift_prop_above (List.length delta) dep pr
        in
          (ctx', pr')
        end

      fun on_kind_wellformness_relation ((ctx, kd), (dep, delta)) =
        let
          val ctx' = shift_context_above delta dep ctx
          val kd' = Passes.TermShift.shift_kind_above (List.length delta) dep kd
        in
          (ctx', kd')
        end

      fun on_prop_wellformness_relation ((ctx, pr), (dep, delta)) =
        let
          val ctx' = shift_context_above delta dep ctx
          val pr' = Passes.TermShift.shift_prop_above (List.length delta) dep pr
        in
          (ctx', pr')
        end

      fun transformer_typing_derivation (on_tyderiv, on_kdderiv, on_prderiv, on_kdwf) (tyderiv : typing_derivation, down as (dep, delta) : down) =
        let
          fun on_rel tyrel = on_typing_relation (tyrel, down)
        in
          case tyderiv of
            TyDerivAbs (tyrel, kdderiv1, tyderiv2) =>
              let
                val (kdderiv1, ()) = on_kdderiv (kdderiv1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 1, delta))
              in
                SOME (TyDerivAbs (on_rel tyrel, kdderiv1, tyderiv2), ())
              end
          | TyDerivRec (tyrel, kdderiv1, tyderiv2) =>
              let
                val (kdderiv1, ()) = on_kdderiv (kdderiv1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 1, delta))
              in
                SOME (TyDerivRec (on_rel tyrel, kdderiv1, tyderiv2), ())
              end
          | TyDerivCase (tyrel, tyderiv1, tyderiv2, tyderiv3) =>
              let
                val (tyderiv1, ()) = on_tyderiv (tyderiv1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 1, delta))
                val (tyderiv3, ()) = on_tyderiv (tyderiv3, (dep + 1, delta))
              in
                SOME (TyDerivCase (on_rel tyrel, tyderiv1, tyderiv2, tyderiv3), ())
              end
          | TyDerivUnpack (tyrel, tyderiv1, tyderiv2) =>
              let
                val (tyderiv1, ()) = on_tyderiv (tyderiv1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 2, delta))
              in
                 SOME (TyDerivUnpack (on_rel tyrel, tyderiv1, tyderiv2), ())
              end
          | TyDerivCstrAbs (tyrel, kdwf1, tyderiv2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 1, delta))
              in
                SOME (TyDerivCstrAbs (on_rel tyrel, kdwf1, tyderiv2), ())
              end
          | TyDerivLet (tyrel, tyderiv1, tyderiv2) =>
              let
                val (tyderiv1, ()) = on_tyderiv (tyderiv1, down)
                val (tyderiv2, ()) = on_tyderiv (tyderiv2, (dep + 1, delta))
              in
                SOME (TyDerivLet (on_rel tyrel, tyderiv1, tyderiv2), ())
              end
          | _ => NONE
        end

      fun transformer_kinding_derivation (on_kdderiv, on_prderiv, on_kdwf) (kdderiv : kinding_derivation, down as (dep, delta) : down) =
        let
          fun on_rel kdrel = on_kinding_relation (kdrel, down)
        in
          case kdderiv of
            KdDerivRefine (kdrel, kdderiv1, prderiv2) =>
              let
                val (kdderiv1, ()) = on_kdderiv (kdderiv1, down)
                val (prderiv2, ()) = on_prderiv (prderiv2, (dep + 1, delta))
              in
                SOME (KdDerivRefine (on_rel kdrel, kdderiv1, prderiv2), ())
              end
          | KdDerivTimeAbs (kdrel, kdderiv1) =>
              let
                val (kdderiv1, ()) = on_kdderiv (kdderiv1, (dep + 1, delta))
              in
                SOME (KdDerivTimeAbs (on_rel kdrel, kdderiv1), ())
              end
          | KdDerivAbs (kdrel, kdwf1, kdderiv2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (kdderiv2, ()) = on_kdderiv (kdderiv2, (dep + 1, delta))
              in
                SOME (KdDerivAbs (on_rel kdrel, kdwf1, kdderiv2), ())
              end
          | KdDerivForall (kdrel, kdwf1, kdderiv2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (kdderiv2, ()) = on_kdderiv (kdderiv2, (dep + 1, delta))
              in
                SOME (KdDerivForall (on_rel kdrel, kdwf1, kdderiv2), ())
              end
          | KdDerivExists (kdrel, kdwf1, kdderiv2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (kdderiv2, ()) = on_kdderiv (kdderiv2, (dep + 1, delta))
              in
                SOME (KdDerivExists (on_rel kdrel, kdwf1, kdderiv2), ())
              end
          | KdDerivRec (kdrel, kdwf1, kdderiv2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (kdderiv2, ()) = on_kdderiv (kdderiv2, (dep + 1, delta))
              in
                SOME (KdDerivRec (on_rel kdrel, kdwf1, kdderiv2), ())
              end
          | _ => NONE
        end

      fun transformer_proping_derivation _ = NONE

      fun transformer_kind_wellformness_derivation (on_kdwf, on_prwf) (kdwf : kind_wellformedness_derivation, down as (dep, delta) : down) =
        let
          fun on_rel kdrel = on_kind_wellformness_relation (kdrel, down)
        in
          case kdwf of
            KdWfDerivSubset (kdrel, kdwf1, prwf2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (prwf2, ()) = on_prwf (prwf2, (dep + 1, delta))
              in
                SOME (KdWfDerivSubset (on_rel kdrel, kdwf1, prwf2), ())
              end
          | _ => NONE
        end

      fun transformer_prop_wellformness_derivation (on_prwf, on_kdwf, on_kdderiv) (prwf : prop_wellformedness_derivation, down as (dep, delta) : down) =
        let
          fun on_rel prrel = on_prop_wellformness_relation (prrel, down)
        in
          case prwf of
            PrWfDerivForall (prrel, kdwf1, prwf2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (prwf2, ()) = on_prwf (prwf2, (dep + 1, delta))
              in
                SOME (PrWfDerivForall (on_rel prrel, kdwf1, prwf2), ())
              end
          | PrWfDerivExists (prrel, kdwf1, prwf2) =>
              let
                val (kdwf1, ()) = on_kdwf (kdwf1, down)
                val (prwf2, ()) = on_prwf (prwf2, (dep + 1, delta))
              in
                SOME (PrWfDerivExists (on_rel prrel, kdwf1, prwf2), ())
              end
          | _ => NONE
        end
    end

    structure TypingDerivationShiftIns = TypingDerivationTransformPass(TypingDerivationShiftHelper)
    open TypingDerivationShiftIns

    fun shift_typing_derivation_above delta dep tyderiv = #1 (transform_typing_derivation (tyderiv, (dep, delta)))
    fun shift_kinding_derivation_above delta dep kdderiv = #1 (transform_kinding_derivation (kdderiv, (dep, delta)))
  end

  structure ANF =
  struct
    open TypingDerivationShift
    exception Impossible

    fun extract_tyrel tyderiv =
      case tyderiv of
        TyDerivVar rel => rel
      | TyDerivInt rel => rel
      | TyDerivNat rel => rel
      | TyDerivUnit rel => rel
      | TyDerivApp (rel, _, _) => rel
      | TyDerivAbs (rel, _, _) => rel
      | TyDerivRec (rel, _, _) => rel
      | TyDerivPair (rel, _, _) => rel
      | TyDerivFst (rel, _) => rel
      | TyDerivSnd (rel, _) => rel
      | TyDerivInLeft (rel, _, _) => rel
      | TyDerivInRight (rel, _, _) => rel
      | TyDerivCase (rel, _, _, _) => rel
      | TyDerivFold (rel, _, _) => rel
      | TyDerivUnfold (rel, _) => rel
      | TyDerivPack (rel, _, _, _) => rel
      | TyDerivUnpack (rel, _, _) => rel
      | TyDerivCstrAbs (rel, _, _) => rel
      | TyDerivCstrApp (rel, _, _) => rel
      | TyDerivBinOp (rel, _, _) => rel
      | TyDerivArrayNew (rel, _, _) => rel
      | TyDerivArrayGet (rel, _, _, _) => rel
      | TyDerivArrayPut (rel, _, _, _, _) => rel
      | TyDerivLet (rel, _, _) => rel
      | TyDerivNever (rel, _) => rel

    fun extract_kdrel kdderiv =
      case kdderiv of
        KdDerivRefine (rel, _, _) => rel
      | KdDerivVar rel => rel
      | KdDerivNat rel => rel
      | KdDerivTime rel => rel
      | KdDerivUnit rel => rel
      | KdDerivTrue rel => rel
      | KdDerivFalse rel => rel
      | KdDerivUnOp (rel, _) => rel
      | KdDerivBinOp (rel, _, _) => rel
      | KdDerivIte (rel, _, _, _) => rel
      | KdDerivTimeAbs (rel, _) => rel
      | KdDerivProd (rel, _, _) => rel
      | KdDerivSum (rel, _, _) => rel
      | KdDerivArrow (rel, _, _, _) => rel
      | KdDerivAbs (rel, _, _) => rel
      | KdDerivApp (rel, _, _) => rel
      | KdDerivForall (rel, _, _) => rel
      | KdDerivExists (rel, _, _) => rel
      | KdDerivRec (rel, _, _) => rel
      | KdDerivTypeUnit rel => rel
      | KdDerivTypeInt rel => rel
      | KdDerivTypeNat (rel, _) => rel
      | KdDerivTypeArray (rel, _, _) => rel

    fun extract_cstr_arrow (CstrArrow r) = r
      | extract_cstr_arrow _ = raise Impossible

    fun extract_cstr_prod (CstrProd r) = r
      | extract_cstr_prod _ = raise Impossible

    fun extract_cstr_sum (CstrSum r) = r
      | extract_cstr_sum _ = raise Impossible

    fun extract_tm_abs (TmAbs r) = r
      | extract_tm_abs _ = raise Impossible

    fun extract_tm_rec (TmRec r) = r
      | extract_tm_rec _ = raise Impossible

    fun normalize_derivation tyderiv = normalize tyderiv (fn (x, d) => x)

    and normalize tyderiv k =
      case tyderiv of
        TyDerivVar _ => k (tyderiv, [])
      | TyDerivInt _ => k (tyderiv, [])
      | TyDerivNat _ => k (tyderiv, [])
      | TyDerivUnit _ => k (tyderiv, [])
      | TyDerivApp (tyrel, tyderiv1, tyderiv2) =>
          normalize_shift tyderiv1 (fn (tyderiv1_new, d1) =>
            normalize_shift (shift_typing_derivation_above d1 0 tyderiv2) (fn (tyderiv2_new, d2) =>
              let
                val tyderiv1_new = shift_typing_derivation_above d2 0 tyderiv1_new
                val tyrel1_new = extract_tyrel tyderiv1_new
                val tyrel2_new = extract_tyrel tyderiv2_new
                val (ty1, ty2, ti) = extract_cstr_arrow (#3 tyrel1_new)
                val tyrel_new = (#1 tyrel2_new, TmApp (#2 tyrel1_new, #2 tyrel2_new), ty2, CstrBinOp (CstrBopAdd, CstrBinOp (CstrBopAdd, CstrBinOp (CstrBopAdd, #4 tyrel1_new, #4 tyrel2_new), CstrNat 1), ti))
              in
                k (TyDerivApp (tyrel_new, tyderiv1_new, tyderiv2_new), List.concat [d2, d1])
              end))
      | TyDerivAbs (tyrel, kdderiv1, tyderiv2) =>
          let
            val (kd1, tm2) = extract_tm_abs (#2 tyrel)
            val tyderiv2_new = normalize_derivation tyderiv2
            val tyrel2_new = extract_tyrel tyderiv2_new
            val tyrel_new = (#1 tyrel, TmAbs (kd1, #2 tyrel2_new), #3 tyrel, CstrNat 0)
          in
            k (TyDerivAbs (tyrel_new, kdderiv1, tyderiv2_new), [])
          end
      | TyDerivRec (tyrel, kdderiv1, tyderiv2) =>
          let
            val (kd1, tm2) = extract_tm_rec (#2 tyrel)
            val tyderiv2_new = normalize_derivation tyderiv2
            val tyrel2_new = extract_tyrel tyderiv2_new
            val tyrel_new = (#1 tyrel, TmRec (kd1, #2 tyrel2_new), #3 tyrel, CstrNat 0)
          in
            k (TyDerivRec (tyrel_new, kdderiv1, tyderiv2_new), [])
          end
      | TyDerivPair (tyrel, tyderiv1, tyderiv2) =>
          normalize_shift tyderiv1 (fn (tyderiv1_new, d1) =>
            normalize_shift (shift_typing_derivation_above d1 0 tyderiv2) (fn (tyderiv2_new, d2) =>
            let
              val tyderiv1_new = shift_typing_derivation_above d2 0 tyderiv1_new
              val tyrel1_new = extract_tyrel tyderiv1_new
              val tyrel2_new = extract_tyrel tyderiv2_new
              val tyrel_new = (#1 tyrel2_new, TmPair (#2 tyrel1_new, #2 tyrel2_new), CstrProd (#3 tyrel1_new, #3 tyrel2_new), CstrBinOp (CstrBopAdd, #4 tyrel1_new, #4 tyrel2_new))
            in
              k (TyDerivPair (tyrel_new, tyderiv1_new, tyderiv2_new), List.concat [d2, d1])
            end))
      | TyDerivFst (tyrel, tyderiv1) =>
          normalize_shift tyderiv1 (fn (tyderiv1_new, d1) =>
            let
              val tyrel1_new = extract_tyrel tyderiv1_new
              val (ty1, ty2) = extract_cstr_prod (#3 tyrel1_new)
              val tyrel_new = (#1 tyrel1_new, TmFst (#2 tyrel1_new), ty1, #4 tyrel1_new)
            in
              k (TyDerivFst (tyrel_new, tyderiv1_new), d1)
            end)
      | TyDerivSnd (tyrel, tyderiv1) =>
          normalize_shift tyderiv1 (fn (tyderiv1_new, d1) =>
            let
              val tyrel1_new = extract_tyrel tyderiv1_new
              val (ty1, ty2) = extract_cstr_prod (#3 tyrel1_new)
              val tyrel_new = (#1 tyrel1_new, TmSnd (#2 tyrel1_new), ty2, #4 tyrel1_new)
            in
              k (TyDerivSnd (tyrel_new, tyderiv1_new), d1)
            end)
      | TyDerivInLeft (tyrel, kdderiv1, tyderiv2) =>
          normalize_shift tyderiv2 (fn (tyderiv2_new, d2) =>
            let
              val kdderiv1_new = shift_kinding_derivation_above d2 0 kdderiv1
              val kdrel1_new = extract_kdrel kdderiv1_new
              val tyrel2_new = extract_tyrel tyderiv2_new
              val tyrel_new = (#1 tyrel2_new, TmInLeft (#2 tyrel2_new), CstrSum (#3 tyrel2_new, #2 kdrel1_new), #4 tyrel2_new)
            in
              k (TyDerivInLeft (tyrel_new, kdderiv1_new, tyderiv2_new), d2)
            end)
      | TyDerivInRight (tyrel, kdderiv1, tyderiv2) =>
          normalize_shift tyderiv2 (fn (tyderiv2_new, d2) =>
            let
              val kdderiv1_new = shift_kinding_derivation_above d2 0 kdderiv1
              val kdrel1_new = extract_kdrel kdderiv1_new
              val tyrel2_new = extract_tyrel tyderiv2_new
              val tyrel_new = (#1 tyrel2_new, TmInRight (#2 tyrel2_new), CstrSum (#2 kdrel1_new, #3 tyrel2_new), #4 tyrel2_new)
            in
              k (TyDerivInRight (tyrel_new, kdderiv1_new, tyderiv2_new), d2)
            end)
      | TyDerivCase (tyrel, tyderiv1, tyderiv2, tyderiv3) =>
          normalize_shift tyderiv1 (fn (tyderiv1_new, d1) =>
            let
              val tyderiv2_new = shift_typing_derivation_above d1 1 tyderiv2
              val tyderiv3_new = shift_typing_derivation_above d1 1 tyderiv3
              val tyderiv2_new = normalize_derivation tyderiv2_new
              val tyderiv3_new = normalize_derivation tyderiv3_new
              val tyrel2_new = extract_tyrel tyderiv2_new
              val tyrel3_new = extract_tyrel tyderiv3_new
              val tyrel1_new = extract_tyrel tyderiv1_new
              val tyrel_new = (#1 tyrel1_new, TmCase (#2 tyrel1_new, #2 tyrel2_new, #2 tyrel3_new), Passes.TermShift.shift_constr_above ~1 0 (#4 tyrel2_new), CstrBinOp (CstrBopAdd, #4 tyrel1_new, CstrBinOp (CstrBopMax, Passes.TermShift.shift_constr_above ~1 0 (#4 tyrel2_new), Passes.TermShift.shift_constr_above ~1 0 (#4 tyrel3_new))))
            in
              k (TyDerivCase (tyrel_new, tyderiv1_new, tyderiv2_new, tyderiv3_new), d1)
            end)
      | _ => raise Impossible

    and normalize_shift tyderiv k =
      normalize tyderiv (fn (tyderiv, d) =>
        let
          val tyrel = extract_tyrel tyderiv
        in
          if Passes.ANF.is_value (#2 tyrel) then
            k (tyderiv, d)
          else
            let
              val ty = #3 tyrel
              val tyrel_intro_var = (BdType ty :: (#1 tyrel), TmVar 0, ty, CstrNat 0)
              val tyderiv_intro_var = TyDerivVar tyrel_intro_var
              val res = k (tyderiv_intro_var, BdType ty :: d)
              val tyrel_res = extract_tyrel res
              val tm = TmLet (#2 tyrel, #2 tyrel_res)
              val tyrel_let = (#1 tyrel, tm, #3 tyrel_res, CstrBinOp (CstrBopAdd, #4 tyrel, #4 tyrel_res))
              val tyderiv_let = TyDerivLet (tyrel_let, tyderiv, res)
            in
              tyderiv_let
            end
        end)
  end
end