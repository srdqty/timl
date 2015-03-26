Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive. 
Generalizable All Variables.

Require Import List.
Require Import Omega.
Require Import Syntax. 
Require Import Util. 

Inductive cmp m n :=
| LT n' (_ : n = S n') (_ : m < n)
| EQ (_ : m = n)
| GT m' (_ : m = S m') (_ : n < m).

Global Arguments LT [m n] n' _ _ .
Global Arguments EQ [m n] _ .
Global Arguments GT [m n] m' _ _ .

Fixpoint nat_cmp m n : cmp m n.
refine (
    match m, n with
      | 0, 0 => EQ _
      | 0, S n' => LT n' _ _
      | S m', 0 => GT m' _ _
      | S m', S n' => 
        match nat_cmp m' n' with
          | LT _ _ _ => LT n' _ _
          | EQ _ => EQ _
          | GT _ _ _ => GT m' _ _
        end
    end); subst; eauto; omega.
Defined.

Definition default A (def : A) x :=
  match x with
    | Some v => v
    | None => def
  end.

Class Monad m := 
  {
    ret : forall a, a -> m a;
    bind : forall a, m a -> forall b, (a -> m b) -> m b
  }.

Notation "x <- a ;; b" := (bind a (fun x => b)) (at level 90, right associativity).
Notation "a ;;; b" := (bind a (fun _ => b)) (at level 90, right associativity).

Global Instance Monad_option : Monad option :=
  {
    ret := fun A (v : A) => Some v;
    bind := fun A (a : option A) B (f : A -> option B) =>
              match a with
                | Some a => f a
                | None => None
              end
  }.

Class Add a b c := 
  {
    add : a -> b -> c
  }.

Infix "+" := add : G.

Global Instance Add_nat : Add nat nat nat :=
  {
    add := Peano.plus
  }.

Section ctx.

  Variable ctx : context.
  
  Global Instance Add_cexpr : Add (cexpr ctx) (cexpr ctx) (cexpr ctx) :=
    {
      add := Fadd
    }.

  Definition append_path (x : var_path ctx) p : var_path ctx := (fst x, p :: snd x).

  Global Arguments Svar {ctx} _ .
  Global Arguments Sstats {ctx} _ .

  Definition is_pair (s : size ctx) :=
    match s with
      | Svar x => Some (Svar (append_path x Pfst), Svar (append_path x Psnd))
      | Spair a b => Some (a, b)
      | _ => None
    end.

  Definition is_inlinr (s : size ctx) :=
    match s with
      | Svar x => Some (Svar (append_path x Pinl), Svar (append_path x Pinr))
      | Sinlinr a b => Some (a, b)
      | _ => None
    end.

  Definition is_fold (s : size ctx) :=
    match s with
      | Svar x => Some (Svar (append_path x Punfold))
      | Sfold t => Some t
      | _ => None
    end.

  Definition is_hide (s : size ctx) :=
    match s with
      | Svar x => Some (Svar (append_path x Punhide))
      | Shide t => Some t
      | _ => None
    end.

  Definition S0 : size ctx := Sstats (F0, F0).

  Definition query_cmd cmd s :=
    match cmd, s with
      | Pfst, Spair a b => a
      | Psnd, Spair a b => b
      | Pinl, Sinlinr a b => a
      | Pinr, Sinlinr a b => b
      | Punfold, Sfold s => s
      | Punhide, Shide s => s
      | _, Svar x => Svar (append_path x cmd)
      | _, Sstats _ => s (* being conservative *)
      | _, _ => S0 (* type mismatch *)
    end.

  Fixpoint query_path' path s :=
    match path with
      | cmd :: path => 
        let s := query_cmd cmd s in
        query_path' path s
      | nil => s
    end.

  Definition query_path path := query_path' (rev path).

  Local Open Scope prog_scope.

  Definition query_idx idx s : cexpr ctx := stats_get idx $ summarize s.

  Definition query_path_idx path idx s :=
    let s := query_path path s in
    query_idx idx s.

End ctx.

Coercion get_i {t ctx} (x : var t ctx) :=
  match x with
    | Var i _ => i
  end.

Coercion nat_of_ord n (i : 'I_n) := match i with Ordinal m _ => m end.

Fixpoint removen {A} (ls : list A) n :=
  match ls with
    | x :: ls =>
      match n with
        | 0 => ls
        | S n => x :: removen ls n
      end
    | nil => nil
  end.

Require Import Program.

Require Import Bool.
Require Import Compare_dec.

Arguments Var {t ctx} _ _ .

Inductive unvar {t ctx} (x : var t ctx) :=
| unVar n H (_ : x = Var n H)
.

Definition un_var {t ctx} (x : var t ctx) : unvar x.
  destruct x.
  econstructor.
  eauto.
Defined.

Require Import Bedrock.Platform.Cito.GeneralTactics4.
Require Import Bedrock.Platform.Cito.GeneralTactics3.

Notation "# n" := (Var n _) (at level 3).

Lemma remove_after A ls : forall m n (a : A), n < m -> let ls' := removen ls m in nth_error ls n = Some a -> nth_error ls' n = Some a.
Proof.
  simpl.
  induction ls; destruct m; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
  eapply IHls; eauto.
  omega.
Qed.

Lemma remove_before A ls : forall m n (a : A), m < S n -> let ls' := removen ls m in nth_error ls (S n) = Some a -> nth_error ls' n = Some a.
Proof.
  simpl.
  induction ls; destruct m; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
  eapply IHls; eauto.
  omega.
Qed.

Definition ce_neq_b a b := negb (ce_eq_b a b).

Require Import Bedrock.Platform.Cito.StringSetFacts.

Lemma ce_eq_b_iff_conv a b : ce_eq_b a b = false <-> a <> b.
Proof.
  etransitivity.
  { symmetry; eapply not_true_iff_false. }
  eapply iff_not_iff.
  eapply ce_eq_b_iff.
Qed.

Lemma ce_neq_b_iff a b : ce_neq_b a b = true <-> a <> b.
Proof.
  etransitivity.
  { eapply negb_true_iff. }
  eapply ce_eq_b_iff_conv.
Qed.

(* transport_xxx : non-computable casting *)

Definition transport_type {ctx} (t : type ctx) {ctx'} (H : ctx = ctx') : type ctx'.
  subst; eauto.
Defined.

(* cast_xxx : computable casting *)

Definition cast_var {vart} {from} (src : var vart from) {to} (H : from = to) : var vart to.
  refine
    match un_var src with
      | unVar n Hn Hsrc =>
        Var src _
    end.
  subst; simpl in *.
  eauto.
Defined.

Class Cast {A} T :=
  {
    cast : forall (from : A), T from -> forall to, from = to -> T to
  }.

Arguments cast {A T _} {from} _ {to} _ .

Instance Cast_var t : Cast (var t) :=
  {
    cast := @cast_var t
  }.

Definition cast_cexpr {from} (src : cexpr from) {to} (H : from = to) : cexpr to.
  admit.
Defined.

Instance Cast_cexpr : Cast cexpr :=
  {
    cast := @cast_cexpr
  }.

Definition cast_size {from} (src : size from) {to} (H : from = to) : size to.
  admit.
Defined.

Instance Cast_size : Cast size :=
  {
    cast := @cast_size
  }.

Program Fixpoint cast_type {from} (src : type from) {to} (H : from = to) : type to :=
  match src with
    | Tvar x => Tvar (cast x H)
    | Tarrow a c s b => Tarrow (cast_type a H) (cast c _) (cast s _) (cast_type b _)
    | Tuniversal c s t => Tuniversal (cast c H) (cast s H) (cast_type t _)
    | Tabs t => Tabs (cast_type t _)
    | Tapp a b => Tapp (cast_type a H) (cast_type b H)
    | Trecur t => Trecur (cast_type t _)
    | Thide t => Thide (cast_type t H)
    | Tunit => Tunit _
    | Tprod a b => Tprod (cast_type a H) (cast_type b H)
    | Tsum a b => Tsum (cast_type a H) (cast_type b H)
  end.

Instance Cast_type : Cast type :=
  {
    cast := @cast_type
  }.

Definition cast_expr {from} (t : expr from) {to} (H : from = to) : expr to.
  admit.
Defined.

Instance Cast_expr : Cast expr :=
  {
    cast := @cast_expr
  }.

Module test_compute.

  Definition ctx := [CEexpr; CEtype].

  Goal (match Tvar (@Var CEtype ctx 1 (eq_refl true)) with
         | Tvar x => get_i x
         | _ => 100 end) = 1. Proof. eapply eq_refl. Qed.

  Variable ctx' : context.
  Hypothesis ctx_ctx' : ctx = ctx'.

  (* won't compute *)
  (* Eval compute in *)
  (*     (match transport_type (Tvar (@Var ctx CEtype 1 (eq_refl true))) ctx_ctx' with *)
  (*        | Tvar x => get_i x *)
  (*        | _ => 100 end). *)

  Goal (match cast_type (Tvar (@Var CEtype ctx 1 (eq_refl true))) ctx_ctx' with
          | Tvar x => get_i x
          | _ => 100 end) = 1. Proof. eapply eq_refl. Qed.

  Goal (match cast_type (Tvar (@Var CEtype ctx 1 (eq_refl true))) ctx_ctx' with
          | Tvar x => match un_var x with
                        | unVar n _ _ => n
                      end
          | _ => 100 end) = 1. Proof. eapply eq_refl. Qed.

End test_compute.

Lemma remove_prefix A (ls1 : list A) : forall ls2 n, removen (ls1 ++ ls2) (length ls1 + n) = ls1 ++ removen ls2 n.
Proof.
  induction ls1; simpl in *; intros; eauto; f_equal; eauto.
Qed.

Definition insert {A} (ls : list A) n new := firstn n ls ++ new ++ skipn n ls.

Lemma insert_after A ls : forall m n new (a : A), n < m -> let ls' := insert ls m new in nth_error ls n = Some a -> nth_error ls' n = Some a.
Proof.
  simpl.
  induction ls; destruct m; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
  eapply IHls; eauto.
  omega.
Qed.

Require Import Bedrock.Platform.Cito.ListFacts4.

Lemma nth_error_prefix A ls1 : forall ls2 n (a : A), nth_error ls2 n = Some a -> nth_error (ls1 ++ ls2) (length ls1 + n) = Some a.
Proof.
  induction ls1; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
Qed.

Lemma nth_error_at A ls1 : forall ls2 (a : A), nth_error (ls1 ++ a :: ls2) (length ls1) = Some a.
Proof.
  intros.
  rewrite <- (plus_0_r (length ls1)).
  eapply nth_error_prefix; eauto.
Qed.

Lemma insert_at A ls : forall n new (a : A), let ls' := insert ls n new in nth_error ls n = Some a -> nth_error ls' (length new + n) = Some a.
Proof.
  Arguments insert {_} _ _ _ / .
  simpl.
  induction ls; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
  {
    simpl.
    inject H.
    rewrite plus_0_r.
    eapply nth_error_at.
  }
  {
    rewrite <- plus_n_Sm.
    simpl.
    eapply IHls; eauto.
  }
Qed.

Lemma insert_before A ls : forall m n new (a : A), m < n -> let ls' := insert ls m new in nth_error ls n = Some a -> nth_error ls' (length new + n) = Some a.
Proof.
  simpl.
  induction ls; destruct m; destruct n; simpl in *; intros; try discriminate; try omega; eauto.
  {
    eapply nth_error_prefix; eauto.
  }
  {
    rewrite <- plus_n_Sm.
    simpl.
    eapply IHls; eauto.
    omega.
  }
Qed.

Lemma insert_prefix A (ls1 : list A) : forall ls2 n new, insert (ls1 ++ ls2) (length ls1 + n) new = ls1 ++ insert ls2 n new.
Proof.
  induction ls1; simpl in *; intros; eauto; f_equal; eauto.
Qed.

Fixpoint iter {A} n f (x : A) :=
  match n with
    | 0 => x
    | S n' => iter n' f (f x)
  end.

Global Arguments fst {A B} _.
Global Arguments snd {A B} _.

(********** Generic traversing ***************)

Fixpoint visit_f {ctx ctx'} (f : (var CEexpr ctx -> var CEexpr ctx') + (var CEexpr ctx -> path -> stat_idx -> cexpr ctx')) (fm : cexpr ctx) : cexpr ctx' :=
  match fm with
    | Fvar (nv, path) i => 
      match f with
        | inl f => Fvar (f nv, path) i
        | inr f => f nv path i
      end
    | F0 => @F0 ctx'
    | Fadd a b => Fadd (visit_f f a) (visit_f f b)
    | F1 => @F1 ctx'
    | Fmul a b => Fmul (visit_f f a) (visit_f f b)
    | Fscale c n => Fscale c (visit_f f n)
    | Fmax a b => Fmax (visit_f f a) (visit_f f b)
    | Flog b n => Flog b (visit_f f n)
    | Fexp b n => Fexp b (visit_f f n)
    | Fminus1 c => Fminus1 (visit_f f c)
  end.

Definition map_stats {ctx A} (f : cexpr ctx -> A) (ss : stats ctx) := 
  match ss with
    | (n0, n1) => (f n0, f n1)
  end.

Local Open Scope prog_scope.

Fixpoint visit_s {ctx ctx'} (f : ((var CEexpr ctx -> var CEexpr ctx') + (var CEexpr ctx -> path -> size ctx')) * (cexpr ctx -> cexpr ctx')) (s : size ctx) : size ctx' :=
  let (fv, ff) := f in
  match s with
    | Svar (nv, path) => 
      match fv with 
        | inl fv => Svar (fv nv, path)
        | inr fv => fv nv path
      end
    | Sstats ss => Sstats $ map_stats ff ss
    | Spair a b => Spair (visit_s f a) (visit_s f b)
    | Sinlinr a b => Sinlinr (visit_s f a) (visit_s f b)
    | Sfold s => Sfold (visit_s f s)
    | Shide s => Shide (visit_s f s)
  end.

Unset Implicit Arguments.

Fixpoint visit_t {ctx ctx'} qctx (f : ((forall qctx, var CEtype (qctx ++ ctx) -> var CEtype (qctx ++ ctx')) + (forall qctx, var CEtype (qctx ++ ctx) -> type (qctx ++ ctx'))) * (forall qctx, cexpr (qctx ++ ctx) -> cexpr (qctx ++ ctx')) * (forall qctx, size (qctx ++ ctx) -> size (qctx ++ ctx'))) (b : type (qctx ++ ctx)) : type (qctx ++ ctx') :=
  let fv := fst (fst f) in
  let ff := snd (fst f) in
  let fs := snd f in
  match b with
    | Tvar n' => 
      match fv with
        | inl fv => Tvar (fv _ n')
        | inr fv => fv _ n'
      end
    | Tarrow a time retsize b => Tarrow (visit_t _ f a) (ff (CEexpr :: _) time) (fs (CEexpr :: _) retsize) (visit_t (CEexpr :: _) f b)
    | Tuniversal time retsize t => Tuniversal (ff _ time) (fs _ retsize) (visit_t (CEtype :: _) f t) 
    | Tabs t => Tabs (visit_t (CEtype :: _) f t) 
    | Tapp a b => Tapp (visit_t _ f a) (visit_t _ f b)
    | Trecur t => Trecur (visit_t (CEtype :: _) f t) 
    | Thide t => Thide (visit_t _ f t)
    | Tunit => Tunit _
    | Tprod a b => Tprod (visit_t _ f a) (visit_t _ f b)
    | Tsum a b => Tsum (visit_t _ f a) (visit_t _ f b)
  end
.

Fixpoint visit_e {ctx ctx'} qctx (f : ((forall qctx, var CEexpr (qctx ++ ctx) -> var CEexpr (qctx ++ ctx')) + (forall qctx, var CEexpr (qctx ++ ctx) -> expr (qctx ++ ctx'))) * (forall qctx, type (qctx ++ ctx) -> type (qctx ++ ctx'))) (b : expr (qctx ++ ctx)) : expr (qctx ++ ctx') :=
  let (fv, ft) := f in
  match b with
    | Evar n' => 
      match fv with
        | inl fv => Evar (fv _ n')
        | inr fv => fv _ n'
      end
    | Eapp a b => Eapp (visit_e _ f a) (visit_e _ f b)
    | Eabs t e => Eabs (ft _ t) (visit_e (CEexpr :: _) f e)
    | Elet def main => Elet (visit_e _ f def) (visit_e (CEexpr :: _) f main)
    | Etapp e t => Etapp (visit_e _ f e) (ft _ t)
    | Etabs e => Etabs (visit_e (CEtype :: _) f e)
    | Efold t e => Efold (ft _ t) (visit_e _ f e)
    | Eunfold e => Eunfold (visit_e _ f e)
    | Ehide e =>Ehide (visit_e _ f e)
    | Eunhide e =>Eunhide (visit_e _ f e)
    | Ett => Ett _
    | Epair a b => Epair (visit_e _ f a) (visit_e _ f b)
    | Einl t e => Einl (ft _ t) (visit_e _ f e)
    | Einr t e => Einr (ft _ t) (visit_e _ f e)
    | Ematch_pair target handler => Ematch_pair (visit_e _ f target) (visit_e (CEexpr :: CEexpr :: _) f handler)
    | Ematch_sum target a b => Ematch_sum (visit_e _ f target) (visit_e (CEexpr :: _) f a) (visit_e (CEexpr :: _) f b)
  end.

(************ Consume ***************)
(* 'consume x b' is is similar to 'substn x v b', except that it knows x is not in b, so it only removes x from b's context, without substitution.  *)

Class Consume var_t T := 
  {
    consume : forall ctx (n : var var_t ctx), T ctx -> T (removen ctx n)
  }.

Arguments consume {_ _ _ ctx} _ _ .

Definition consume_cast `{Consume var_t B, Cast _ B} {ctx} (x : var var_t ctx) qctx (b : B (qctx ++ ctx)) : B (qctx ++ removen ctx x).
  refine
    match un_var x with
      | unVar n Hn Hni =>
        cast (consume #(length qctx + n) b) _
    end.
  {
    subst; simpl in *.
    eapply remove_prefix.
  }
  Grab Existential Variables.
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    eapply ceb_iff.
    unfold_all.
    subst.
    simpl in *.
    eapply nth_error_prefix; eauto.
  }
Defined.

Definition consume_v t_var1 t_var2 (Hneq : ce_neq_b t_var1 t_var2 = true) ctx (x : var t_var1 ctx) (xv : var t_var2 ctx) : var t_var2 (removen ctx x).
  refine
    match un_var x, un_var xv with
      | unVar n Hn Hni, unVar nv Hnv Hniv =>
        match nat_cmp nv n with 
          | GT p Heq Hlt => #p
          | LT p Heq Hlt => #nv
          | EQ Heq => _
        end
    end.
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    simpl in *.
    eapply remove_after; eauto.
  }
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    subst.
    simpl in *.
    erewrite Hn' in Hnv'.
    inject Hnv'.
    eapply ce_neq_b_iff in Hneq.
    intuition.
  }
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    simpl in *.
    eapply remove_before; eauto.
  }
Defined.

Global Instance Consume_var_t_e : Consume CEtype (var CEexpr) :=
  {
    consume := consume_v CEtype CEexpr eq_refl
  }.

Global Instance Consume_var_e_t : Consume CEexpr (var CEtype) :=
  {
    consume := consume_v CEexpr CEtype eq_refl
  }.

Definition consume_f {ctx} x f :=
  visit_f
    (inl (consume (ctx := ctx) x))
    f.

Global Instance Consume_cexpr : Consume CEtype cexpr :=
  {
    consume := @consume_f
  }.

Definition consume_s {ctx} x s :=
  visit_s
    (inl (consume (ctx := ctx) x),
     consume x) 
    s.

Global Instance Consume_size : Consume CEtype size :=
  {
    consume := @consume_s
  }.

(*
Definition consume_t {ctx} x t :=
  visit_t
    []
    (inl (consume (ctx := ctx) x),
     consume_cast x,
     consume_cast x)
    t.

Global Instance Consume_type : Consume type :=
  {
    consume := consume_t
  }.

Definition consume_e x e :=
  visit_e 0 (consume_e_f x, consume_cast x) e.

Global Instance Consume_expr : Consume expr :=
  {
    consume := consume_e
  }.
*)

(************* Shift **************)

Class Shift {A} T := 
  {
    shift : forall ctx new n, T ctx -> T (@insert A ctx n new)
  }.

Arguments shift {_ _ _ _} _ _ _ .

Definition shift_from `{Shift T} {ctx} new n := shift (ctx := ctx) [new] n.
Definition shift1 `{Shift T} {ctx} new := shift_from (ctx := ctx) new 0.

Definition shift_cast `{Shift A T, Cast _ T} {ctx} new n qctx (b : T (qctx ++ ctx)) : T (qctx ++ insert ctx n new).
  refine
    (cast (shift new (length qctx + n) b) _).
  eapply insert_prefix.
Defined.

Definition shift_v {t ctx} new n (xv : var t ctx) : var t (insert ctx n new).
  refine
    match un_var xv with
      | unVar nv Hnv Hniv =>
        match nat_cmp nv n with
          | LT _ _ _ => #nv
          | _ => #(length new + nv)
        end
    end.
  {
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    eapply insert_after; eauto.
  }
  {
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    simpl in *.
    eapply insert_at; eauto.
  }
  {
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    eapply insert_before; eauto.
  }
Defined.

Global Instance Shift_var t : Shift (var t) :=
  {
    shift := @shift_v t
  }.

Definition shift_f {ctx} new n f :=
  visit_f (inl (shift (ctx := ctx) new n)) f.

Global Instance Shift_cexpr : Shift cexpr :=
  {
    shift := @shift_f
  }.

Definition shift_s {ctx} new n s :=
  visit_s
    (inl (shift (ctx := ctx) new n),
    shift new n)
    s.

Global Instance Shift_size : Shift size :=
  {
    shift := @shift_s
  }.

Definition shift_t {ctx} new n t :=
  visit_t [] (inl (shift_cast (ctx := ctx) new n), shift_cast new n, shift_cast new n) t.

Global Instance Shift_type : Shift type :=
  {
    shift := @shift_t
  }.

Definition shift_e {ctx} new n e :=
  visit_e [] (inl (shift_cast (ctx := ctx) new n), shift_cast new n) e.

Global Instance Shift_expr : Shift expr :=
  {
    shift := @shift_e
  }.

(****************** Subst ****************)

(* substitute for a designated free variable x *)
Class Subst var_t value body :=
  {
    substx : forall ctx (x : var var_t ctx), value (removen ctx x) -> body ctx -> body (removen ctx x)
  }.

Arguments substx {_ _ _ _ _} _ _ _ .

Lemma ceb_iff_c {a b} : a = b -> ceb a b = true.
  intros; eapply ceb_iff; eauto.
Qed.

(* substitute for the outmost free variable *)
Definition subst `{Subst var_t V B} {ctx} (v : V ctx) (b : B (var_t :: ctx)) : B ctx := substx (@Var var_t (var_t :: ctx) 0 (ceb_iff_c eq_refl)) v b.

(*
Definition subst_list `{Subst V B} `{Shift V} (values : list V) (e : B) := 
  fst $ fold_left (fun p v => let '(b, x) := p in (substx x (shift x v) b, x - 1)) values (e, length values - 1).
*)

Definition subst_v {vart T ctx} (x : var vart ctx) (xv : var vart ctx) (f : option (var vart (removen ctx x)) -> T (removen ctx x)) : T (removen ctx x).
  refine
    match un_var x, un_var xv with
      | unVar n Hn Hni, unVar nv Hnv Hniv =>
        match nat_cmp nv n with 
          | LT p Heq Hlt => f (Some #nv)
          | EQ Heq => f None
          | GT p Heq Hlt => f (Some #p)
        end
    end.
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    simpl in *.
    eapply remove_after; eauto.
  }
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    copy_as Hnv Hnv'.
    eapply ceb_iff in Hnv'.
    eapply ceb_iff.
    subst.
    simpl in *.
    eapply remove_before; eauto.
  }
Defined.
  
Definition subst_v_cast `{Shift _ T, Cast _ T} {vart} (f : forall ctx, var vart ctx -> T ctx) ctx (x : var vart ctx) (v : T (removen ctx x)) qctx (xv : var vart (qctx ++ ctx)) : T (qctx ++ removen ctx x).
  refine
    match un_var x with
      | unVar n Hn Hni =>
        cast (subst_v 
                (ctx := qctx ++ ctx)
                #(length qctx + n) xv
                (fun x => 
                   match x with
                     | None => cast (shift qctx 0 v) _
                     | Some x => f _ x
                   end)) _
    end.
  {
    subst; simpl in *.
    symmetry; eapply remove_prefix.
  }
  {
    subst; simpl in *.
    eapply remove_prefix.
  }
  Grab Existential Variables.
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    eapply ceb_iff.
    unfold_all.
    subst.
    simpl in *.
    eapply nth_error_prefix; eauto.
  }
Defined.

Definition subst_cast `{Subst var_t V B, Shift _ V, Cast _ V, Cast _ B} {ctx} (x : var var_t ctx) (v : V (removen ctx x)) qctx (b : B (qctx ++ ctx)) : B (qctx ++ removen ctx x).
  refine
    match un_var x with
      | unVar n Hn Hni =>
        cast (substx #(length qctx + n) (cast (shift qctx 0 v) _) b) _
    end.
  {
    subst; simpl in *.
    symmetry; eapply remove_prefix.
  }
  {
    subst; simpl in *.
    eapply remove_prefix.
  }
  Grab Existential Variables.
  {
    copy_as Hn Hn'.
    eapply ceb_iff in Hn'.
    eapply ceb_iff.
    unfold_all.
    subst.
    simpl in *.
    eapply nth_error_prefix; eauto.
  }
Defined.

Definition subst_s_f_f {ctx} x v xv path i :=
  (subst_v 
     (ctx := ctx)
     x xv
     (fun x => 
        match x with
          | None => query_path_idx path i v
          | Some x => Fvar (x, path) i
        end)).

Definition subst_s_f {ctx} x v b :=
  visit_f (ctx := ctx) (inr (subst_s_f_f x v)) b.

Global Instance Subst_size_cexpr : Subst CEexpr size cexpr :=
  {
    substx := @subst_s_f
  }.

Definition subst_s_s_f {ctx} x v xv path :=
  (subst_v 
     (ctx := ctx)
     x xv
     (fun x => 
        match x with
          | None => query_path path v
          | Some x => Svar (x, path)
        end)).

Definition subst_s_s {ctx} x v b :=
  visit_s 
    (ctx := ctx)
    (inr (subst_s_s_f x v),
    substx x v) 
    b.

Global Instance Subst_size_size : Subst CEexpr size size :=
  {
    substx := @subst_s_s
  }.

Definition subst_t_t {ctx} x v b := 
  visit_t 
    [] 
    (inr (subst_v_cast (@Tvar) ctx x v), 
     consume_cast x, 
     consume_cast x) 
    b.

Global Instance Subst_type_type : Subst CEtype type type :=
  {
    substx := @subst_t_t
  }.

Definition subst_s_t {ctx} x v b :=
  visit_t
    (ctx := ctx)
    [] 
    (inl (consume_cast x),
     subst_cast x v,
     subst_cast x v)
    b.

Global Instance Subst_size_type : Subst CEexpr size type :=
  {
    substx := @subst_s_t
  }.

Definition get_size {ctx} (e : expr ctx) : size ctx.
  admit.
Defined.

Definition subst_e_e {ctx} x v b := 
  visit_e 
    [] 
    (inr (subst_v_cast (@Evar) ctx x v), 
     subst_cast x (get_size v)) 
    b.

Global Instance Subst_expr_expr : Subst CEexpr expr expr :=
  {
    substx := @subst_e_e
  }.

Definition subst_t_e {ctx} x v b :=
  visit_e
    (ctx := ctx) 
    []
    (inl (consume_cast x),
     subst_cast x v)
    b.

Global Instance Subst_type_expr : Subst CEtype type expr :=
  {
    substx := @subst_t_e
  }.

