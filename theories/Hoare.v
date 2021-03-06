From CoindSemWhile Require Import SsrExport Trace Language Semax Assert AssertClassical.

Set Implicit Arguments.
Unset Strict Implicit.
Import Prenex Implicits.

Definition udt (u: assertS) (x: id) (a: expr): assertS :=
fun st => exists st0 : state, (u st0) /\ (update x (a st0) st0 = st).

Inductive hsemax : assertS -> stmt -> assertS -> Prop :=

| hsemax_skip: forall u,   hsemax u Sskip u 

| hsemax_assign: forall u x a, 
  hsemax u (Sassign x a) (udt u x a) 

| hsemax_seq: forall s1 s2 u1 u2 u3,
  hsemax u1 s1 u2->
  hsemax u2 s2 u3 ->
  hsemax u1 (Sseq s1 s2)  u3

| hsemax_ifthenelse: forall a s1 s2 u1 u2,
  hsemax (u1 andS eval_true a) s1 u2 ->
  hsemax (u1 andS eval_false a) s2 u2 ->
  hsemax u1 (Sifthenelse a s1 s2) u2

| hsemax_while:forall a s u,
  hsemax  (u andS eval_true a) s u ->
  hsemax u (Swhile a s) (u andS eval_false a)

| hsemax_conseq: forall s u1 u2 v1 v2,
  u1 ->> u2 -> 
  v2 ->> v1 -> 
  hsemax u2 s v2 ->
  hsemax u1 s v1

| hsemax_ex: forall s (A : Type) (u: A -> assertS) (v: A -> assertS),
  (forall x, hsemax (u x) s (v x)) ->
  hsemax (exS u) s (exS v). 

Lemma hsemax_conseq_L: forall s u1 u2 v,
u1 ->> u2 -> hsemax u2 s v -> hsemax u1 s v.
Proof.
move => s u1 u2 v h0 h1.
exact: hsemax_conseq h0 (@assertS_imp_refl v) h1.
Qed.

Lemma hsemax_conseq_R: forall s u v1 v2,
v2 ->> v1 -> hsemax u s v2 -> hsemax u s v1. 
Proof. 
move => s u v1 v2 h0 h1. 
have := hsemax_conseq (@assertS_imp_refl u)  h0 h1. 
by apply. 
Qed.

Lemma Last_destruct : forall (p: assertT) st tr,
 satisfy p tr -> fin tr st -> Last p st.
Proof. 
move => [f h] st tr h0 h1. simpl. simpl in h0. exists tr. 
by split. 
Qed.

(* Proposition 4.3: projecting the trace-based Hoare logic into 
   the partial-correctness Hoare logic. *)
Lemma semax_correct_hsemax: forall u s p, 
semax u s p -> forall v, hsemax (v andS u) s (Last ([|v|] *** p)).
Proof.
induction 1. 
- move => v. have h0 := hsemax_skip (v andS u).
  have h1 := (@singleton_andS_append u v).
  have := hsemax_conseq_R h1 h0. by apply.  
- move => v. have h0 := hsemax_assign (v andS u) x a.
  have h1: (udt (v andS u) x a) ->> (Last ([|v|] *** Updt u x a)). 
  * clear h0. move => st0 h0. move: h0 => [st1 [[h0 h1] h2]]. 
     exists (Tcons st1 (Tnil st0)). split. exists (Tnil st1). split. 
     exists st1; split => //. by apply bisim_reflexive. apply follows_nil.
     by simpl. rewrite /updt. exists st1. split => //.
     rewrite h2. by apply bisim_reflexive. apply fin_delay. apply fin_nil.  
  have := hsemax_conseq_R h1 h0. by apply. 
- move => v0. 
  have h: Last ([|Last ([|v0|] *** p1 *** [|v|])|] *** p2) ->> 
  Last ([|v0|] *** p1 *** p2).
  * move => st0 h0. have h1 := Last_Last h0 => {h0}.
    have := Last_monotone _ h1 => {h1}. apply. clear st0. 
    have h0 := (@Append_assoc_L ([|v0|]) (p1 *** ([|v|])) p2). 
    have := impT_conseq_L h0. apply. clear h0.
    apply Append_monotone_R. apply Append_monotone_L. apply Append_Singleton. 
  have := hsemax_conseq_R h. apply. have := hsemax_seq (IHsemax1 _). apply. 
  have := hsemax_conseq_L _ (IHsemax2 _). apply. move => st0. move => h0. 
  split. done. have := (@Last_chop_sglt ([|v0|] *** p1) v). apply. 
  have := Last_monotone _ h0. apply. apply Append_assoc_R.   
- move => v.
  have hpost : (Last ([|v andS u|] *** p)) ->> (Last ([|v|] *** <<u>> *** p)). 
  * destruct p as [p hp]. move => st0 h0. simpl. move: h0 => [tr0 [h0 h1]]. 
     move: h0 => [tr1 [h0 h2]]. move: h0 => [st1 [h4 h3]]. foo h3. 
     foo h2. move: h4 => [h2 h3]. exists (Tcons (hd tr0) tr0). 
     split. exists (Tnil (hd tr0)). split. exists (hd tr0). 
     split => //. by apply bisim_reflexive. apply follows_nil =>//.
     exists (Tcons (hd tr0) (Tnil (hd tr0))). split. exists (hd tr0). 
     split => //. by apply bisim_reflexive. apply follows_delay.
     apply follows_nil =>//. apply fin_delay. done. 
  apply hsemax_ifthenelse. 
  * have hpre: ((v andS u) andS eval_true a) ->> 
     ((v andS u) andS u andS eval_true a).
      * move => st0 [h0 h1]. split => //. move: h0 => [h0 h2]. by split. 
     have h0 := IHsemax1 (v andS u) => {IHsemax1}.
     have := hsemax_conseq_L hpre h0 => {h0}. move => h0. 
     have := hsemax_conseq_R hpost h0. apply.
  * have hpre: ((v andS u) andS eval_false a) ->> 
     ((v andS u) andS u andS eval_false a).
      * move => st0 [h0 h1]. split => //. move: h0 => [h0 h2]. by split.  
     have h0 := IHsemax2 (v andS u) => {IHsemax1 IHsemax2}. 
     have := hsemax_conseq_L hpre h0 => {h0}. move => h0. 
     have := hsemax_conseq_R hpost h0. apply. 
- move => w.  
  set inv := Last ([|w|] *** <<u0>> *** Iter ( p *** <<u>>)). 
  have h0 := IHsemax inv => {IHsemax H0}.
  have h1: (inv andS eval_true a) ->> (inv andS u andS eval_true a).
  * clear h0. move => st [h0 h1]. split => //. split => //. clear h1. 
    destruct p as [f hf]. simpl in inv. move: h0 => [tr [h0 h1]]. 
    move: h0 => [tr0 [h0 h2]]. move: h0 => [st0 [_ h3]]. foo h3.
    foo h2. move: H2 => [tr0 [h3 h2]]. move: h3 => [st0 [h3 h4]]. foo h4. 
    foo H2. foo h2. foo h1. foo H3. have h0 := H _ h3 => {h3}.
    have h1: satisfy (ttT *** [|u|]) tr'. 
    * apply iter_last. simpl. exists (Tnil (hd tr')). split. 
      exists (hd tr'). split => //. by apply bisim_nil. 
      apply follows_nil => //. 
      have := iter_cont (@append_cont_L _ _ _ _)  H2.
      apply. done. 
    simpl in h1. clear H2 h0. move: h1 => [tr0 [_ h1]]. 
    move: tr' st H4 tr0 h1. induction 1. 
    - move => tr0 h0. foo h0. move: H1 => [st0 [h0 h1]]. by foo h1.
    - move => tr0 h0. foo h0. move: H1 => [st0 [_ h0]]. foo h0. 
      have := IHfin _ H2. by apply.            
  have h2 := hsemax_conseq_L h1 h0 => {h0 h1}.
  have h0 : Last ([|inv|] *** p *** [|u|]) ->> inv.
  * clear h2.  move => st0 h0. have h1 := Last_Last h0 => {h0}.
    have := Last_monotone (@Append_assoc_L _ _ _). apply.  
    have := Last_monotone (@Append_monotone_R _ _ _ (@Iter_unfold_1 _)). 
    apply. have := Last_monotone (@Append_assoc_L _ _ _). apply. 
    have := Last_monotone (@Append_assoc_L _ _ _). apply. 
    have : Last ((((([|w|]) *** (<< u0 >>)) *** Iter (p *** (<< u >>))) *** p) ***
    ([|u|])) st0.
    * have := Last_monotone (@Append_assoc_R _ _ _). apply.
       have := Last_monotone (Append_monotone_L (@Append_assoc_R _ _ _)).
       apply. done. clear h1. move => h1.  
       have := Last_dup h1. done. 
    have h1 := hsemax_conseq_R h0 h2 => {h0 h2}.
    have h0 := hsemax_while h1 => {h1}. 
    have := hsemax_conseq _ _ h0. apply. 
    * clear h0. move => st0 h0. rewrite /inv. have := Last_monotone 
      (@Append_monotone_R _ _ _ (@Append_monotone_R  _ _ _ (@Stop_Iter _))).
      apply. move: h0 => [h0 h1].  exists (Tcons st0 (Tnil st0)). split.
      exists (Tnil st0). split. exists st0. split => //. apply bisim_reflexive. 
      apply follows_nil. by simpl. exists (Tcons st0 (Tnil st0)). split. 
      exists st0. split => //. by apply bisim_reflexive. apply follows_delay. 
      apply follows_nil. by simpl. exists st0. split => //. by apply bisim_reflexive. 
      apply fin_delay. apply fin_nil. 
    * rewrite /inv. move => st0 [h1 h2]. 
      have := Last_monotone (@Append_assoc_L _ _ _). apply. 
      have := Last_monotone (@Append_assoc_L _ _ _). apply.
      have := Last_monotone (@Append_monotone_L _ _ _ (@Append_assoc_R _ _ _)). 
      apply. destruct p as [p hp]. move: h1 => [tr0 [h1 h3]]. simpl.
      exists tr0. split => //. exists tr0. split => //. clear h1. move: tr0 h3.
      cofix hcoind. move => tr0 h1. foo h1. apply follows_nil. by simpl.
      exists st0. split => //. apply bisim_reflexive. apply follows_delay. 
      have := hcoind _ H0. by apply.         
- move => v. have h := IHsemax v => {IHsemax}. 
  have h0 := andS_cont (@assertS_imp_refl _) H.
  have := hsemax_conseq_L (h0 _). apply. clear h0. 
  have := hsemax_conseq_R _ h. apply. clear h. 
  apply Last_monotone. have := Append_monotone_R. apply. done. 
- move => v.    
  have: (v andS exS u) ->> (exS (fun a => v andS u a)).
  * move => st0 [h0 [x h1]]. exists x. split => //. 
  move => h0. have := hsemax_conseq_L h0 => {h0}. apply.   
  have: (exS (fun x => Last ([|v|] *** (p x)))) ->> Last ([|v|] *** exT p).
  * move => st0. move => [x h0]. move hp: (p x) => q. rewrite hp in h0. 
    destruct q as [q hq]. simpl in h0. destruct h0 as [tr0 [h0 h1]].
    exists tr0. split => //. clear h1. destruct h0 as [tr1 [h0 h1]]. 
    exists tr1. split => //. clear h0. move: tr1 tr0 h1. cofix hcoind.
    move => tr0 tr1 h0. foo h0. apply follows_nil => //. exists x.
    rewrite hp. simpl => //. apply follows_delay.
    have := hcoind _ _ H1. done. 
  move => h0. have := hsemax_conseq_R h0. apply. clear h0. 
  apply hsemax_ex. done. 
Qed.

(* Corollary 4.2 *)
Lemma semax_correct_hsemax_main: forall u s p, 
semax u s p -> hsemax u s (Last p).
Proof.
move => U s P hhsemax. have := (semax_correct_hsemax hhsemax ttS) => {hhsemax}.
move => hhsemax. have := (hsemax_conseq _ _ hhsemax); apply => {hhsemax}. 
 * move => st0 hU. split => //. 
 * move => st0 h0. destruct P as [P hP]. destruct h0 as [tr0 [h0 h1]].
   exists tr0. split => //. destruct h0 as [h0  [h2 h3]]. 
   inversion h2; subst; clear h2. destruct H as [_ h2]. clear h1. 
   inversion h2; subst; clear h2. inversion h3; subst; clear h3. 
   done. 
Qed. 

(* Proposition 4.1: embedding the partial-correctness Hoare logic 
   into the trace-based Hoare logic *)
Lemma hsemax_correct_semax: forall u s v, 
hsemax u s v -> semax u s (ttT *** [|v|]). 
Proof. 
induction 1.
- have h0 := semax_skip u.
  have h1: ([|u|]) =>> (ttT *** [|u|]).
  * move => tr0 [st0 [h1 h2]]. foo h2. exists (Tnil st0). split => //. 
     apply follows_nil =>//. exists st0. split; [done | apply bisim_nil]. 
  have := semax_conseq_R h1 h0. by apply.     
- have h0 := semax_assign u x a. 
  have h1: (Updt u x a) =>> (ttT *** [|udt u x a|]). 
  * move => tr0 [st0 [h1 h2]]. exists tr0. split => //. foo h2. foo H1.
    apply follows_delay. apply follows_nil. by simpl. exists (update x (a st0) st0). 
    split; last apply bisim_nil. exists st0. by split.   
  have := semax_conseq_R h1 h0. by apply.  
- have h0 := semax_seq IHhsemax1 IHhsemax2 => {IHhsemax1 IHhsemax2}. 
  have h1 := semax_conseq_R (@Append_assoc_R _ _ _) h0 => {h0}.
  have := (semax_conseq_R (@Append_monotone_L _ _ _ (@ttT_idem_comp)) h1).
  by apply. 
- have h0 := semax_ifthenelse IHhsemax1 IHhsemax2 => {IHhsemax1 IHhsemax2 H H0}. 
  have h1: (<<u1>> *** ttT *** [|u2|]) =>> (ttT *** [|u2|]). 
  * clear h0. move => tr0 h0. have h1 := append_assoc_R h0 => {h0}.
    move: h1 => [tr1 [h0 h1]]. exists tr1. by split. 
  have := semax_conseq_R h1 h0. by apply.      
- have h0: u ->> u; first done.
  have h1 := semax_while h0 IHhsemax => {h0 IHhsemax}.  
  set p0 := (ttT *** << u >>).
  have h0: ((<< u >>) *** Iter p0 *** [|eval_false a|]) =>> 
  (ttT *** [|u andS eval_false a|]). 
  * clear h1. move => tr0 [tr1 [h0 h1]]. move: h0 => [st0 [h0 h2]].
     foo h2. foo H2. foo h1. foo H3. exists (Tcons (hd tr') tr'). 
     split; first done. apply follows_delay. move: tr' H2 h0. 
     cofix hcoind0. move => tr0 h0 h1. move: h0 => [tr1 [h0 h2]].
     foo h0. foo h2. move: H2 => [st0 [h0 h2]]. foo h2. simpl in h1. 
     apply follows_nil => //. exists st0. split => //. apply bisim_reflexive.
     clear h1. move: tr tr1 tr0 H0 H1 h2. cofix hcoind1. 
     move => tr0 tr1 tr2 h0 h1 h2. move: h0 => [tr3 [h0 h3]]. foo h3. 
     clear h0. move: H1 => [st0 [h0 h3]]. foo h3. foo H2. foo h1. 
    foo H3. foo h2. have h1 := follows_hd H4. rewrite h1 in h0 => {h1}. 
    have := follows_delay (hd tr'). apply. have := hcoind0 _ _ h0. apply.
    exists tr'. split; by [apply H4 | apply H2]. foo h1. foo h2. 
    clear h0 hcoind0. apply follows_delay. 
    have := hcoind1 _ _ _ _ H4 H5. apply. exists tr. split; [done | apply H0].  
  have := semax_conseq_R h0 h1. by apply.   
- have h0 := Singleton_monotone H0.
  have h1 := (@Append_monotone_R ttT _ _ h0) => {h0}.
  have h0 := semax_conseq_R h1 IHhsemax => {h1 IHhsemax}.
  have := semax_conseq_L H h0. apply. 
- have: (exT (fun x => ttT *** [|v x|])) =>> (ttT *** [|exS v|]). 
  * move => tr0 [x h0]. simpl in h0. simpl. destruct h0 as [tr1 [h0 h1]]. 
    exists tr1. split => //. clear h0. move: tr1 tr0 h1. cofix hcoind. 
    move => tr0 tr1 h0. foo h0. apply follows_nil => //. destruct H2 as [st0 [h0 h1]]. 
    exists st0; split => //. exists x. done. apply follows_delay. 
    have := hcoind _ _ H1. apply. 
  move => h0. have := semax_conseq_R h0. apply. clear h0. 
  apply semax_ex =>//.   
Qed.
