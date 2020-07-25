/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Kenny Lau, Johan Commelin, Mario Carneiro, Kevin Buzzard,
Amelia Livingston, Yury Kudryashov
-/
import data.set.lattice

/-!
# Submonoids: definition and `complete_lattice` structure

This file defines bundled multiplicative and additive submonoids. We also define
a `complete_lattice` structure on `submonoid`s, define the closure of a set as the minimal submonoid
that includes this set, and prove a few results about extending properties from a dense set (i.e.
a set with `closure s = ⊤`) to the whole monoid, see `submonoid.dense_induction` and
`monoid_hom.of_mdense`.

## Main definitions

* `submonoid M`: the type of bundled submonoids of a monoid `M`; the underlying set is given in
  the `carrier` field of the structure, and should be accessed through coercion as in `(S : set M)`.
* `add_submonoid M` : the type of bundled submonoids of an additive monoid `M`.

For each of the following definitions in the `submonoid` namespace, there is a corresponding
definition in the `add_submonoid` namespace.

* `submonoid.copy` : copy of a submonoid with `carrier` replaced by a set that is equal but possibly
  not definitionally equal to the carrier of the original `submonoid`.
* `submonoid.closure` :  monoid closure of a set, i.e., the least submonoid that includes the set.
* `submonoid.gi` : `closure : set M → submonoid M` and coercion `coe : submonoid M → set M`
  form a `galois_insertion`;
* `monoid_hom.eq_mlocus`: the submonoid of elements `x : M` such that `f x = g x`;
* `monoid_hom.of_mdense`:  if a map `f : M → N` between two monoids satisfies `f 1 = 1` and
  `f (x * y) = f x * f y` for `y` from some dense set `s`, then `f` is a monoid homomorphism.
  E.g., if `f : ℕ → M` satisfies `f 0 = 0` and `f (x + 1) = f x + f 1`, then `f` is an additive
  monoid homomorphism.

## Implementation notes

Submonoid inclusion is denoted `≤` rather than `⊆`, although `∈` is defined as
membership of a submonoid's underlying set.

This file is designed to have very few dependencies. In particular, it should not use natural
numbers.

## Tags
submonoid, submonoids
-/

variables {M : Type*} [monoid M] {s : set M}
variables {A : Type*} [add_monoid A] {t : set A}

/-- A submonoid of a monoid `M` is a subset containing 1 and closed under multiplication. -/
structure submonoid (M : Type*) [monoid M] :=
(carrier : set M)
(one_mem' : (1 : M) ∈ carrier)
(mul_mem' {a b} : a ∈ carrier → b ∈ carrier → a * b ∈ carrier)

/-- An additive submonoid of an additive monoid `M` is a subset containing 0 and
  closed under addition. -/
structure add_submonoid (M : Type*) [add_monoid M] :=
(carrier : set M)
(zero_mem' : (0 : M) ∈ carrier)
(add_mem' {a b} : a ∈ carrier → b ∈ carrier → a + b ∈ carrier)

attribute [to_additive add_submonoid] submonoid

namespace submonoid

@[to_additive]
instance : has_coe (submonoid M) (set M) := ⟨submonoid.carrier⟩

@[to_additive]
instance : has_coe_to_sort (submonoid M) := ⟨Type*, λ S, S.carrier⟩

@[to_additive]
instance : has_mem M (submonoid M) := ⟨λ m S, m ∈ (S:set M)⟩

@[simp, to_additive]
lemma mem_carrier {s : submonoid M} {x : M} : x ∈ s.carrier ↔ x ∈ s := iff.rfl

@[simp, norm_cast, to_additive]
lemma mem_coe {S : submonoid M} {m : M} : m ∈ (S : set M) ↔ m ∈ S := iff.rfl

@[simp, norm_cast, to_additive]
lemma coe_coe (s : submonoid M) : ↥(s : set M) = s := rfl

attribute [norm_cast] add_submonoid.mem_coe add_submonoid.coe_coe

@[to_additive]
protected lemma «exists» {s : submonoid M} {p : s → Prop} :
  (∃ x : s, p x) ↔ ∃ x ∈ s, p ⟨x, ‹x ∈ s›⟩ :=
set_coe.exists

@[to_additive]
protected lemma «forall» {s : submonoid M} {p : s → Prop} :
  (∀ x : s, p x) ↔ ∀ x ∈ s, p ⟨x, ‹x ∈ s›⟩ :=
set_coe.forall

/-- Two submonoids are equal if the underlying subsets are equal. -/
@[to_additive "Two `add_submonoid`s are equal if the underlying subsets are equal."]
theorem ext' ⦃S T : submonoid M⦄ (h : (S : set M) = T) : S = T :=
by cases S; cases T; congr'

/-- Two submonoids are equal if and only if the underlying subsets are equal. -/
@[to_additive "Two `add_submonoid`s are equal if and only if the underlying subsets are equal."]
protected theorem ext'_iff {S T : submonoid M}  : S = T ↔ (S : set M) = T :=
⟨λ h, h ▸ rfl, λ h, ext' h⟩

/-- Two submonoids are equal if they have the same elements. -/
@[ext, to_additive "Two `add_submonoid`s are equal if they have the same elements."]
theorem ext {S T : submonoid M}
  (h : ∀ x, x ∈ S ↔ x ∈ T) : S = T := ext' $ set.ext h

attribute [ext] add_submonoid.ext

/-- Copy a submonoid replacing `carrier` with a set that is equal to it. -/
@[to_additive "Copy an additive submonoid replacing `carrier` with a set that is equal to it."]
def copy (S : submonoid M) (s : set M) (hs : s = S) : submonoid M :=
{ carrier := s,
  one_mem' := hs.symm ▸ S.one_mem',
  mul_mem' := hs.symm ▸ S.mul_mem' }

variable {S : submonoid M}

@[simp, to_additive] lemma coe_copy {s : set M} (hs : s = S) :
  (S.copy s hs : set M) = s := rfl

@[to_additive] lemma copy_eq {s : set M} (hs : s = S) : S.copy s hs = S := ext' hs

variable (S)

/-- A submonoid contains the monoid's 1. -/
@[to_additive "An `add_submonoid` contains the monoid's 0."]
theorem one_mem : (1 : M) ∈ S := S.one_mem'

/-- A submonoid is closed under multiplication. -/
@[to_additive "An `add_submonoid` is closed under addition."]
theorem mul_mem {x y : M} : x ∈ S → y ∈ S → x * y ∈ S := submonoid.mul_mem' S

@[to_additive] lemma coe_injective : function.injective (coe : S → M) := subtype.val_injective

@[simp, to_additive] lemma coe_eq_coe (x y : S) : (x : M) = y ↔ x = y := set_coe.ext_iff
attribute [norm_cast] coe_eq_coe add_submonoid.coe_eq_coe

@[to_additive]
instance : has_le (submonoid M) := ⟨λ S T, ∀ ⦃x⦄, x ∈ S → x ∈ T⟩

@[to_additive]
lemma le_def {S T : submonoid M} : S ≤ T ↔ ∀ ⦃x : M⦄, x ∈ S → x ∈ T := iff.rfl

@[simp, norm_cast, to_additive]
lemma coe_subset_coe {S T : submonoid M} : (S : set M) ⊆ T ↔ S ≤ T := iff.rfl

@[to_additive]
instance : partial_order (submonoid M) :=
{ le := λ S T, ∀ ⦃x⦄, x ∈ S → x ∈ T,
  .. partial_order.lift (coe : submonoid M → set M) ext' }

@[simp, norm_cast, to_additive]
lemma coe_ssubset_coe {S T : submonoid M} : (S : set M) ⊂ T ↔ S < T := iff.rfl

attribute [norm_cast]  add_submonoid.coe_subset_coe add_submonoid.coe_ssubset_coe

/-- The submonoid `M` of the monoid `M`. -/
@[to_additive "The additive submonoid `M` of the `add_monoid M`."]
instance : has_top (submonoid M) :=
⟨{ carrier := set.univ,
   one_mem' := set.mem_univ 1,
   mul_mem' := λ _ _ _ _, set.mem_univ _ }⟩

/-- The trivial submonoid `{1}` of an monoid `M`. -/
@[to_additive "The trivial `add_submonoid` `{0}` of an `add_monoid` `M`."]
instance : has_bot (submonoid M) :=
⟨{ carrier := {1},
   one_mem' := set.mem_singleton 1,
   mul_mem' := λ a b ha hb, by { simp only [set.mem_singleton_iff] at *, rw [ha, hb, mul_one] }}⟩

@[to_additive]
instance : inhabited (submonoid M) := ⟨⊥⟩

@[simp, to_additive] lemma mem_bot {x : M} : x ∈ (⊥ : submonoid M) ↔ x = 1 := set.mem_singleton_iff

@[simp, to_additive] lemma mem_top (x : M) : x ∈ (⊤ : submonoid M) := set.mem_univ x

@[simp, to_additive] lemma coe_top : ((⊤ : submonoid M) : set M) = set.univ := rfl

@[simp, to_additive] lemma coe_bot : ((⊥ : submonoid M) : set M) = {1} := rfl

/-- The inf of two submonoids is their intersection. -/
@[to_additive "The inf of two `add_submonoid`s is their intersection."]
instance : has_inf (submonoid M) :=
⟨λ S₁ S₂,
  { carrier := S₁ ∩ S₂,
    one_mem' := ⟨S₁.one_mem, S₂.one_mem⟩,
    mul_mem' := λ _ _ ⟨hx, hx'⟩ ⟨hy, hy'⟩,
      ⟨S₁.mul_mem hx hy, S₂.mul_mem hx' hy'⟩ }⟩

@[simp, to_additive]
lemma coe_inf (p p' : submonoid M) : ((p ⊓ p' : submonoid M) : set M) = p ∩ p' := rfl

@[simp, to_additive]
lemma mem_inf {p p' : submonoid M} {x : M} : x ∈ p ⊓ p' ↔ x ∈ p ∧ x ∈ p' := iff.rfl

@[to_additive]
instance : has_Inf (submonoid M) :=
⟨λ s, {
  carrier := ⋂ t ∈ s, ↑t,
  one_mem' := set.mem_bInter $ λ i h, i.one_mem,
  mul_mem' := λ x y hx hy, set.mem_bInter $ λ i h,
    i.mul_mem (by apply set.mem_bInter_iff.1 hx i h) (by apply set.mem_bInter_iff.1 hy i h) }⟩

@[simp, to_additive]
lemma coe_Inf (S : set (submonoid M)) : ((Inf S : submonoid M) : set M) = ⋂ s ∈ S, ↑s := rfl

@[to_additive]
lemma mem_Inf {S : set (submonoid M)} {x : M} : x ∈ Inf S ↔ ∀ p ∈ S, x ∈ p := set.mem_bInter_iff

@[to_additive]
lemma mem_infi {ι : Sort*} {S : ι → submonoid M} {x : M} : (x ∈ ⨅ i, S i) ↔ ∀ i, x ∈ S i :=
by simp only [infi, mem_Inf, set.forall_range_iff]

@[simp, to_additive]
lemma coe_infi {ι : Sort*} {S : ι → submonoid M} : (↑(⨅ i, S i) : set M) = ⋂ i, S i :=
by simp only [infi, coe_Inf, set.bInter_range]

attribute [norm_cast] coe_Inf coe_infi

/-- Submonoids of a monoid form a complete lattice. -/
@[to_additive "The `add_submonoid`s of an `add_monoid` form a complete lattice."]
instance : complete_lattice (submonoid M) :=
{ le           := (≤),
  lt           := (<),
  bot          := (⊥),
  bot_le       := λ S x hx, (mem_bot.1 hx).symm ▸ S.one_mem,
  top          := (⊤),
  le_top       := λ S x hx, mem_top x,
  inf          := (⊓),
  Inf          := has_Inf.Inf,
  le_inf       := λ a b c ha hb x hx, ⟨ha hx, hb hx⟩,
  inf_le_left  := λ a b x, and.left,
  inf_le_right := λ a b x, and.right,
  .. complete_lattice_of_Inf (submonoid M) $ λ s,
    is_glb.of_image (λ S T, show (S : set M) ≤ T ↔ S ≤ T, from coe_subset_coe) is_glb_binfi }

/-- The `submonoid` generated by a set. -/
@[to_additive "The `add_submonoid` generated by a set"]
def closure (s : set M) : submonoid M := Inf {S | s ⊆ S}

@[to_additive]
lemma mem_closure {x : M} : x ∈ closure s ↔ ∀ S : submonoid M, s ⊆ S → x ∈ S :=
mem_Inf

/-- The submonoid generated by a set includes the set. -/
@[simp, to_additive "The `add_submonoid` generated by a set includes the set."]
lemma subset_closure : s ⊆ closure s := λ x hx, mem_closure.2 $ λ S hS, hS hx

variable {S}
open set

/-- A submonoid `S` includes `closure s` if and only if it includes `s`. -/
@[simp, to_additive "An additive submonoid `S` includes `closure s` if and only if it includes `s`"]
lemma closure_le : closure s ≤ S ↔ s ⊆ S :=
⟨subset.trans subset_closure, λ h, Inf_le h⟩

/-- Submonoid closure of a set is monotone in its argument: if `s ⊆ t`,
then `closure s ≤ closure t`. -/
@[to_additive "Additive submonoid closure of a set is monotone in its argument: if `s ⊆ t`,
then `closure s ≤ closure t`"]
lemma closure_mono ⦃s t : set M⦄ (h : s ⊆ t) : closure s ≤ closure t :=
closure_le.2 $ subset.trans h subset_closure

@[to_additive]
lemma closure_eq_of_le (h₁ : s ⊆ S) (h₂ : S ≤ closure s) : closure s = S :=
le_antisymm (closure_le.2 h₁) h₂

variable (S)

/-- An induction principle for closure membership. If `p` holds for `1` and all elements of `s`, and
is preserved under multiplication, then `p` holds for all elements of the closure of `s`. -/
@[to_additive "An induction principle for additive closure membership. If `p` holds for `0` and all
elements of `s`, and is preserved under addition, then `p` holds for all elements
of the additive closure of `s`."]
lemma closure_induction {p : M → Prop} {x} (h : x ∈ closure s)
  (Hs : ∀ x ∈ s, p x) (H1 : p 1)
  (Hmul : ∀ x y, p x → p y → p (x * y)) : p x :=
(@closure_le _ _ _ ⟨p, H1, Hmul⟩).2 Hs h

attribute [elab_as_eliminator] submonoid.closure_induction add_submonoid.closure_induction

/-- If `s` is a dense set in a monoid `M`, `submonoid.closure s = ⊤`, then in order to prove that
some predicate `p` holds for all `x : M` it suffices to verify `p x` for `x ∈ s`, verify `p 1`,
and verify that `p x` and `p y` imply `p (x * y)`. -/
@[to_additive]
lemma dense_induction {p : M → Prop} (x : M) {s : set M} (hs : closure s = ⊤)
  (Hs : ∀ x ∈ s, p x) (H1 : p 1)
  (Hmul : ∀ x y, p x → p y → p (x * y)) : p x :=
have ∀ x ∈ closure s, p x, from λ x hx, closure_induction hx Hs H1 Hmul,
by simpa [hs] using this x

/-- If `s` is a dense set in an additive monoid `M`, `add_submonoid.closure s = ⊤`, then in order
to prove that some predicate `p` holds for all `x : M` it suffices to verify `p x` for `x ∈ s`,
verify `p 0`, and verify that `p x` and `p y` imply `p (x + y)`. -/
add_decl_doc add_submonoid.dense_induction

attribute [elab_as_eliminator] dense_induction add_submonoid.dense_induction

variable (M)

/-- `closure` forms a Galois insertion with the coercion to set. -/
@[to_additive "`closure` forms a Galois insertion with the coercion to set."]
protected def gi : galois_insertion (@closure M _) coe :=
{ choice := λ s _, closure s,
  gc := λ s t, closure_le,
  le_l_u := λ s, subset_closure,
  choice_eq := λ s h, rfl }

variable {M}

/-- Closure of a submonoid `S` equals `S`. -/
@[simp, to_additive "Additive closure of an additive submonoid `S` equals `S`"]
lemma closure_eq : closure (S : set M) = S := (submonoid.gi M).l_u_eq S

@[simp, to_additive] lemma closure_empty : closure (∅ : set M) = ⊥ :=
(submonoid.gi M).gc.l_bot

@[simp, to_additive] lemma closure_univ : closure (univ : set M) = ⊤ :=
@coe_top M _ ▸ closure_eq ⊤

@[to_additive]
lemma closure_union (s t : set M) : closure (s ∪ t) = closure s ⊔ closure t :=
(submonoid.gi M).gc.l_sup

@[to_additive]
lemma closure_Union {ι} (s : ι → set M) : closure (⋃ i, s i) = ⨆ i, closure (s i) :=
(submonoid.gi M).gc.l_supr

end submonoid

namespace monoid_hom

variables {N : Type*} {P : Type*} [monoid N] [monoid P] (S : submonoid M)

open submonoid

/-- The submonoid of elements `x : M` such that `f x = g x` -/
@[to_additive "The additive submonoid of elements `x : M` such that `f x = g x`"]
def eq_mlocus (f g : M →* N) : submonoid M :=
{ carrier := {x | f x = g x},
  one_mem' := by rw [set.mem_set_of_eq, f.map_one, g.map_one],
  mul_mem' := λ x y (hx : _ = _) (hy : _ = _), by simp [*] }

/-- If two monoid homomorphisms are equal on a set, then they are equal on its submonoid closure. -/
@[to_additive]
lemma eq_on_mclosure {f g : M →* N} {s : set M} (h : set.eq_on f g s) :
  set.eq_on f g (closure s) :=
show closure s ≤ f.eq_mlocus g, from closure_le.2 h

@[to_additive]
lemma eq_of_eq_on_mtop {f g : M →* N} (h : set.eq_on f g (⊤ : submonoid M)) :
  f = g :=
ext $ λ x, h trivial

@[to_additive]
lemma eq_of_eq_on_mdense {s : set M} (hs : closure s = ⊤) {f g : M →* N} (h : s.eq_on f g) :
  f = g :=
eq_of_eq_on_mtop $ hs ▸ eq_on_mclosure h

/-- Let `s` be a subset of a monoid `M` such that the closure of `s` is the whole monoid.
Then `monoid_hom.of_mdense` defines a monoid homomorphism from `M` asking for a proof
of `f (x * y) = f x * f y` only for `y ∈ s`. -/
@[to_additive]
def of_mdense (f : M → N) (hs : closure s = ⊤) (h1 : f 1 = 1)
  (hmul : ∀ x (y ∈ s), f (x * y) = f x * f y) :
  M →* N :=
{ to_fun := f,
  map_one' := h1,
  map_mul' := λ x y, dense_induction y hs (λ y hy x, hmul x y hy) (by simp [h1])
    (λ y₁ y₂ h₁ h₂ x, by simp only [← mul_assoc, h₁, h₂]) x }

/-- Let `s` be a subset of an additive monoid `M` such that the closure of `s` is the whole monoid.
Then `add_monoid_hom.of_mdense` defines an additive monoid homomorphism from `M` asking for a proof
of `f (x + y) = f x + f y` only for `y ∈ s`. -/
add_decl_doc add_monoid_hom.of_mdense

@[simp, to_additive] lemma coe_of_mdense (f : M → N) (hs : closure s = ⊤) (h1 hmul) :
  ⇑(of_mdense f hs h1 hmul) = f := rfl

attribute [norm_cast] coe_of_mdense add_monoid_hom.coe_of_mdense

end monoid_hom
