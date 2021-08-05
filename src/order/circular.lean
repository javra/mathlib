/-
Copyright (c) 2021 Yaël Dillies, Kendall Frey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Kendall Frey
-/
import data.set.basic

/-!
# Circular order hierarchy


## Tags

circular order, cyclic order, circularly ordered set, cyclically ordered set
-/

class has_btw (α : Type*) :=
(btw : α → α → α → Prop)

export has_btw (btw)

class has_sbtw (α : Type*) :=
(sbtw : α → α → α → Prop)

export has_sbtw (sbtw)

/-alias lt_of_le_of_lt  ← has_le.le.trans_lt
alias btw_antisymm     ← has_btw.btw.antisymm
alias lt_of_le_of_ne  ← has_le.le.lt_of_ne
alias lt_of_le_not_le ← has_le.le.lt_of_not_le
alias lt_or_eq_of_le  ← has_le.le.lt_or_eq-/

/-! ### Circular preorders -/

class circular_preorder (α : Type*) extends has_btw α, has_sbtw α :=
(btw_refl : ∀ a : α, btw a a a)
(btw_trans : ∀ a b c d : α, btw a b c → btw a c d → btw a b d)
(sbtw := λ a b c, btw a b c ∧ ¬btw c b a)
(sbtw_cyclic_left : ∀ a b c : α, sbtw a b c → sbtw b c a)
(sbtw_iff_btw_not_btw : ∀ a b c : α, sbtw a b c ↔ (btw a b c ∧ ¬btw c b a) . order_laws_tac)

export circular_preorder (btw_refl) (btw_trans)

section circular_preorder
variables {α : Type*} [circular_preorder α]

lemma btw_rfl {a : α} : btw a a a :=
btw_refl _

lemma btw_trans : ∀ {a b c d : α}, btw a b c → btw a c d → btw a b d :=
circular_preorder.btw_trans
--alias btw_trans        ← has_btw.btw.trans
lemma has_btw.btw.trans {a b c d : α} (h : btw a b c) : btw a c d → btw a b d :=
btw_trans h

lemma sbtw_iff_btw_not_btw : ∀ {a b c : α}, sbtw a b c ↔ btw a b c ∧ ¬btw c b a :=
circular_preorder.sbtw_iff_btw_not_btw

lemma btw_of_sbtw {a b c : α} (h : sbtw a b c) : btw a b c :=
(sbtw_iff_btw_not_btw.1 h).1
--alias btw_of_sbtw        ← has_sbtw.sbtw.btw
lemma has_sbtw.sbtw.btw {a b c : α} (h : sbtw a b c) : btw a b c :=
btw_of_sbtw h

lemma not_btw_of_sbtw {a b c : α} (h : sbtw a b c) : ¬btw c b a :=
(sbtw_iff_btw_not_btw.1 h).2
--alias not_btw_of_sbtw        ← has_sbtw.sbtw.not_btw
lemma has_sbtw.sbtw.not_btw {a b c : α} (h : sbtw a b c) : ¬btw c b a :=
not_btw_of_sbtw h

lemma sbtw_of_btw_not_btw {a b c : α} (habc : btw a b c) (hcba : ¬btw c b a) : sbtw a b c :=
sbtw_iff_btw_not_btw.2 ⟨habc, hcba⟩
--alias sbtw_of_btw_not_btw        ← has_btw.btw.sbtw_of_not_btw
lemma has_btw.btw.sbtw_of_not_btw {a b c : α} (habc : btw a b c) (hcba : ¬btw c b a) : sbtw a b c :=
sbtw_of_btw_not_btw habc hcba

lemma sbtw_cyclic_left : ∀ {a b c : α}, sbtw a b c → sbtw b c a :=
circular_preorder.sbtw_cyclic_left
--alias sbtw_cyclic_left        ← has_sbtw.sbtw.cyclic_left
lemma has_sbtw.sbtw.cyclic_left {a b c : α} (h : sbtw a b c) : sbtw b c a :=
sbtw_cyclic_left h

lemma sbtw_cyclic_right {a b c : α} (h : sbtw a b c) : sbtw c a b :=
h.cyclic_left.cyclic_left
--alias sbtw_cyclic_right        ← has_sbtw.sbtw.cyclic_right
lemma has_sbtw.sbtw.cyclic_right {a b c : α} (h : sbtw a b c) : sbtw c a b :=
sbtw_cyclic_right h

/-- The order of the `↔` has been chosen so that `rw sbtw_cyclic` cycles to the right while
`rw ←sbtw_cyclic` cycles to the left (thus following the prepended arrow). -/
lemma sbtw_cyclic {a b c : α} : sbtw a b c ↔ sbtw c a b :=
⟨sbtw_cyclic_right, sbtw_cyclic_left⟩

lemma btw_self_right_of_btw_self_left {a b : α} (h : btw a a b) : btw b a a :=
begin
  sorry
end

lemma not_sbtw_same_left {a b : α} : ¬ sbtw a a b :=
begin
  rw sbtw_iff_btw_not_btw,
  exact λ h, h.2 (btw_self_right_of_btw_self_left h.1),

end

lemma not_sbtw_same_left_right {a b : α} (h : sbtw a b a) : false :=
h.not_btw h.btw

/-- Circular interval closed-closed -/
def cIcc (a b : α) : set α := {x | btw a x b}

/-- Circular interval closed-open -/
def cIco (a b : α) : set α := {x | btw a x b ∧ ¬btw a b x}

/-- Circular interval open-closed -/
def cIoc (a b : α) : set α := {x | btw a x b ∧ ¬btw x a b}

/-- Circular interval open-open -/
def cIoo (a b : α) : set α := {x | btw a x b ∧ ¬btw a b x ∧ ¬btw x a b}

end circular_preorder

/-! ### Circular partial orders -/

class circular_partial_order (α : Type*) extends circular_preorder α :=
(btw_antisymm : ∀ a b c, btw a b c → btw a c b → b = c)
(eq_of_btw_same_left_right : ∀ a b, btw a b a → a = b)

section circular_partial_order
variables {α : Type*} [circular_partial_order α]

lemma btw_antisymm : ∀ {a b c : α}, btw a b c → btw a c b → b = c :=
circular_partial_order.btw_antisymm
--alias btw_antisymm        ← has_btw.btw.antisymm
lemma has_btw.btw.antisymm {a b c : α} (h : btw a b c) : btw a c b → b = c :=
btw_antisymm h

lemma eq_of_btw_same_left_right : ∀ {a b : α}, btw a b a → a = b :=
circular_partial_order.eq_of_btw_same_left_right

lemma btw_same_left_right_iff {a b : α} : btw a b a ↔ a = b :=
begin
  refine ⟨eq_of_btw_same_left_right, _⟩,
  rintro rfl,
  exact btw_rfl,
end

end circular_partial_order

/-! ### Circular orders -/

class circular_order (α : Type*) extends circular_partial_order α :=
(btw_total : ∀ a b c : α, btw a b c ∨ btw c b a)

export circular_order (btw_total)

section circular_order
variables {α : Type*} [circular_order α]

lemma btw_refl_right (a b : α) : btw a a b :=
begin
  have := btw_total a a b,
  obtain rfl | h := eq_or_ne a b,
  { exact btw_rfl },
  sorry
end

end circular_order

section order_dual

instance (α : Type*) [has_btw α] : has_btw (order_dual α) := ⟨λ a b c : α, btw c b a⟩
instance (α : Type*) [has_sbtw α] : has_sbtw (order_dual α) := ⟨λ a b c : α, sbtw c b a⟩

instance (α : Type*) [h : circular_preorder α] : circular_preorder (order_dual α) :=
{ btw_refl := btw_refl,
  btw_trans := λ a b c d habc hacd, sorry,
  sbtw_cyclic_left := sorry,
  sbtw_iff_btw_not_btw := λ a b c, @sbtw_iff_btw_not_btw α _ c b a,
  .. order_dual.has_btw α,
  .. order_dual.has_sbtw α }

instance (α : Type*) [circular_partial_order α] : circular_partial_order (order_dual α) :=
{ btw_antisymm := λ a b c habc hacb, sorry, --@btw_antisymm α _ _ _ _ hacb habc,
  .. order_dual.circular_preorder α }

instance (α : Type*) [circular_order α] : circular_order (order_dual α) :=
{ btw_total := λ a b c, btw_total c b a, .. order_dual.circular_partial_order α }


end order_dual
