import tactic
import data.real.basic
import linear_algebra.affine_space.independent
import linear_algebra.std_basis
import linear_algebra.affine_space.finite_dimensional
import linear_algebra.affine_space.combination
import linear_algebra.finite_dimensional
import algebra.module.linear_map
import analysis.convex.topology
import combinatorics.simplicial_complex.dump

open_locale classical affine big_operators
open set
--TODO: Generalise to LCTVS
variables {m : ℕ} {E : Type*} [normed_group E] [normed_space ℝ E] {x : E} {A B : set E}

namespace affine

/--
A set B is extreme to a set A if no affine combination of points in A \ B is in B. -/
def extreme_set (A B : set E) :
  Prop :=
B ⊆ A ∧ ∀ x₁ x₂ ∈ A, ∀ x ∈ B, x ∈ segment x₁ x₂ → x₁ ≠ x → x₂ ≠ x → x₁ ∈ B ∧ x₂ ∈ B

lemma extreme_set.antisymm :
  anti_symmetric (extreme_set : set E → set E → Prop) :=
λ A B hAB hBA, subset.antisymm hBA.1 hAB.1

lemma extreme_set.trans :
  transitive (extreme_set : set E → set E → Prop) :=
begin
  rintro A B C ⟨hBA, hAB⟩ ⟨hCB, hBC⟩,
  use subset.trans hCB hBA,
  rintro x₁ x₂ hx₁A hx₂A x hxC hx hxx₁ hxx₂,
  obtain ⟨hx₁B, hx₂B⟩ := hAB x₁ x₂ hx₁A hx₂A x (hCB hxC) hx hxx₁ hxx₂,
  exact hBC x₁ x₂ hx₁B hx₂B x hxC hx hxx₁ hxx₂,
end

lemma convex_remove_of_extreme (hA : convex A) (hAB : extreme_set A B) :
  convex (A \ B) :=
begin
  rw convex_iff_segment_subset,
  rintro x₁ x₂ ⟨hx₁A, hx₁B⟩ ⟨hx₂A, hx₂B⟩ x hx,
  refine ⟨hA.segment_subset hx₁A hx₂A hx, λ hxB, hx₁B (hAB.2 x₁ x₂ hx₁A hx₂A x hxB hx _ _).1⟩,
  { rintro rfl,
    exact hx₁B hxB },
  { rintro rfl,
    exact hx₂B hxB }
end

def extreme_point (A : set E) (x : E) :
  Prop :=
x ∈ A ∧ ∀ (x₁ x₂ ∈ A), x ∈ segment x₁ x₂ → x₁ = x ∨ x₂ = x

lemma extreme_point_iff_extreme_singleton :
  extreme_point A x ↔ extreme_set A {x} :=
begin
  split,
  { rintro ⟨hxA, hx⟩,
    use singleton_subset_iff.2 hxA,
    rintro x₁ x₂ hx₁A hx₂A y (rfl : y = x) hxs hx₁ hx₂,
    exfalso,
    cases hx x₁ x₂ hx₁A hx₂A hxs,
    exacts [hx₁ h, hx₂ h] },
  { rintro hx,
    use singleton_subset_iff.1 hx.1,
    rintro x₁ x₂ hx₁ hx₂ hxs,
    by_contra,
    push_neg at h,
    exact h.1 (hx.2 x₁ x₂ hx₁ hx₂ x rfl hxs h.1 h.2).1 }
end

lemma convex_remove_iff_extreme_point (hA : convex A) (hx : x ∈ A) :
  convex (A \ {x}) ↔ extreme_point A x :=
begin
  split,
  { refine λ hAx, ⟨hx, λ x₁ x₂ hx₁A hx₂A hx, _⟩,
    by_contra,
    push_neg at h,
    rw convex_iff_segment_subset at hAx,
    exact (hAx ⟨hx₁A, λ hx₁, h.1 (mem_singleton_iff.2 hx₁)⟩
      ⟨hx₂A, λ hx₂, h.2 (mem_singleton_iff.2 hx₂)⟩ hx).2 rfl },
  exact λ hx, ((convex_remove_of_extreme hA).2 (extreme_point_iff_extreme_singleton.1 hx)).2,
end

lemma extreme_to_convex_hull_of_affine_independent {s : finset E} (hx : x ∈ s)
  (hs : affine_independent ℝ (λ p, p : (s : set E) → E)) :
  extreme_point (convex_hull ↑s) x :=
begin
  -- have := convex_independent_of_affine_independent hs _ hx,

  -- rw ←convex_remove_iff_is_extreme (convex_convex_hull s) (subset_convex_hull _ hx),
  refine ⟨subset_convex_hull _ hx, _⟩,
  rintro y y' hy hy' t,
  rw finset.convex_hull_eq at hy hy',
  obtain ⟨w, hw₀, hw₁, hy⟩ := hy,
  obtain ⟨w', hw'₀, hw'₁, hy'⟩ := hy',
  -- rcases hy with ⟨ι, q, w, z, hw₀, hw₁ : q.sum w = 1, hz, _⟩,
  -- rcases hy' with ⟨ι', q', w', z', hw'₀, hw'₁ : q'.sum w' = 1, hz', rfl⟩,
  rw segment_eq_image at t,
  obtain ⟨θ, hθ₁, hθ₂ : _ + _ = _⟩ := t,
  rw finset.center_mass_eq_of_sum_1 _ _ hw₁ at hy,
  rw finset.center_mass_eq_of_sum_1 _ _ hw'₁ at hy',
  change s.sum (λ i, w i • i) = y at hy,
  change s.sum (λ i, w' i • i) = y' at hy',
  let w'' : E → ℝ := λ t, (1 - θ) * w t + θ * w' t - if t = x then 1 else 0,
  have hw''₁ : s.sum w'' = 0,
  { rw [finset.sum_sub_distrib, finset.sum_add_distrib, ← finset.mul_sum, ← finset.mul_sum, hw₁,
      hw'₁, finset.sum_ite_eq' s, if_pos hx],
    simp },
  have hw''₂ : s.sum (λ i, w'' i • i) = 0,
  { simp only [sub_smul, add_smul, finset.sum_add_distrib, finset.sum_sub_distrib],
    simp only [mul_smul, ←finset.smul_sum, hy, hy'],
    simp only [ite_smul, zero_smul, one_smul, finset.sum_ite_eq', if_pos hx, hθ₂, sub_self] },
  by_contra t,
  push_neg at t,
  suffices hw''₃ : ∀ q ∈ s, w'' q = 0,
  { have : θ = 0 ∨ θ = 1,
    { by_contra hθ,
      push_neg at hθ,
      have : 0 < θ ∧ 0 < 1 - θ,
      { split,
        { apply lt_of_le_of_ne hθ₁.1 hθ.1.symm },
        { rw sub_pos,
          apply lt_of_le_of_ne hθ₁.2 hθ.2 } },
      have both_zero : ∀ q ∈ s, q ≠ x → w q = 0,
      { intros q hq₁ hq₂,
        specialize hw''₃ q hq₁,
        change _ + _ = _ at hw''₃,
        rw if_neg hq₂ at hw''₃,
        simp only [add_zero, neg_zero] at hw''₃,
        rw add_eq_zero_iff'
            (mul_nonneg (le_of_lt this.2) (hw₀ q hq₁))
            (mul_nonneg (le_of_lt this.1) (hw'₀ q hq₁)) at hw''₃,
        rw mul_eq_zero at hw''₃,
        apply or.resolve_left hw''₃.1 (ne_of_gt this.2) },
      have : (1 - θ) * w x + θ * w' x = 1,
      { specialize hw''₃ _ hx,
        change (1 - θ) * w x + θ * w' x - ite _ _ _ = 0 at hw''₃,
        rwa [if_pos rfl, sub_eq_zero] at hw''₃ },
      rw finset.sum_eq_single x at hw₁,
      { rw finset.sum_eq_single x at hy,
        { rw hw₁ at hy,
          apply t.1,
          rw ←hy,
          simp },
        { rintro q hq₁ hq₂,
          rw both_zero q hq₁ hq₂,
          simp },
        { exact λ t, (t hx).elim } },
      { intros q hq₁ hq₂,
        apply both_zero q hq₁ hq₂ },
      { exact λ t, (t hx).elim } },
    rcases this with (rfl | rfl),
    { simp only [add_zero, one_smul, sub_zero, zero_smul] at hθ₂,
      apply t.1 hθ₂ },
    { simp only [one_smul, zero_smul, zero_add, sub_self] at hθ₂,
      apply t.2 hθ₂ } },
  rw affine_independent_iff_of_fintype at hs,
  let w''' : (s : set E) → ℝ := λ t, w'' (t : E),
  have hw''' : finset.univ.sum w''' = 0,
  { rw coe_sum,
    apply hw''₁ },
  specialize hs w''' hw''' _,
  { rw finset.weighted_vsub_eq_weighted_vsub_of_point_of_sum_eq_zero _ _ _ hw''' (0 : E),
    rw finset.weighted_vsub_of_point_apply,
    simp only [vsub_eq_sub, sub_zero],
    rw coe_sum _ (λ i, w'' i • i),
    apply hw''₂ },
  rintro q hq,
  exact hs ⟨q, hq⟩,
end

--Accurate name?
lemma mem_of_extreme_to_convex_hull {X : set E} {x : E} (hx : extreme_point (convex_hull X) x) :
  x ∈ X :=
begin
  have hxX : x ∈ convex_hull (X : set E) := hx.1,
  rw ←convex_remove_iff_extreme_point (convex_convex_hull _) hxX at hx,
  by_contra,
  have : convex_hull X ⊆ convex_hull X \ {x},
  { apply convex_hull_min _ hx,
    rw subset_diff,
    exact ⟨subset_convex_hull _, disjoint_singleton_right.2 h⟩ },
  rw [subset_diff, disjoint_singleton_right] at this,
  apply this.2 hxX,
end

def exposed_set (A B : set E) :
  Prop :=
∃ l : E → ℝ, is_linear_map ℝ l ∧ continuous l ∧ B = {x | x ∈ A ∧ l x = (⨆ y ∈ A, l y)}

lemma subset_of_exposed (hAB : exposed_set A B) :
  B ⊆ A :=
begin
  obtain ⟨_, _, _, rfl⟩ := hAB,
  exact λ x hx, hx.1,
end

lemma exposed_set.antisymm :
  anti_symmetric (exposed_set : set E → set E → Prop) :=
λ A B hAB hBA, subset.antisymm (subset_of_exposed hBA) (subset_of_exposed hAB)

lemma exposed_set.trans :
  transitive (exposed_set : set E → set E → Prop) :=
begin
  rintro A B C ⟨l₁, hl₁lin, hl₁con, hB⟩ ⟨l₂, hl₂lin, hl₂cont, hC⟩,
  --have := λ x, (⨆ (y : E) (H : y ∈ B), lBC y) * lAB x + (⨆ (y : E) (H : y ∈ A), lAB y) * lBC x,
  let u : ℝ := sorry,
  let v : ℝ := sorry,
  refine ⟨λ x, u * l₁ x + v * l₂ x, sorry, sorry, _⟩, --use weighed sum instead
  rw hC,
  have : (⨆ (y : E) (H : y ∈ A), u * l₁ y + v * l₂ y) = (⨆ (y : E) (H : y ∈ A), u * l₁ y) +
    (⨆ (y : E) (H : y ∈ A), v * l₂ y) := sorry,
  have : ∀ x : E, u * l₁ x + v * l₂ x = (⨆ (y : E) (H : y ∈ A), u * l₁ y + v * l₂ y)
    ↔ u * l₁ x = (⨆ (y : E) (H : y ∈ A), u * l₁ y) ∧ v * l₂ x = ⨆ (y : E) (H : y ∈ A), v * l₂ y,
    sorry,
  --simp,
  ext x,
  split,
  {
    rintro ⟨hxB, hxl₂⟩,
    rw hB at hxB,
    obtain ⟨hxA, hxl₁⟩ := id hxB,
    use hxA,
    apply le_antisymm,
    { sorry },
    rw [hxl₁, hxl₂],
    sorry
  },
  {
    rintro ⟨hxA, h⟩,
    rw hB,
    refine ⟨⟨hxA, _⟩, _⟩,
    have : l₁ x ≤ ⨆ (y : E) (H : y ∈ A), l₁ y,
    {
      sorry,
    },
    apply le_antisymm this,
    sorry,
    sorry
  }
end

lemma extreme_of_exposed (hAB : exposed_set A B) :
  extreme_set A B :=
begin
  use subset_of_exposed hAB,
  rintro x₁ x₂ hx₁A hx₂A x hxB ⟨a, b, ha, hb, hab, hx⟩ hx₁x hx₂x,
  obtain ⟨l, hllin, hlcon, rfl⟩ := hAB,
  suffices h : (l x₁ = ⨆ (y : E) (H : y ∈ A), l y) ∧ l x₂ = ⨆ (y : E) (H : y ∈ A), l y,
  { exact ⟨⟨hx₁A, h.1⟩, ⟨hx₂A, h.2⟩⟩ },
  have : l x = a • l x₁ + b • l x₂ := by rw [←hx, hllin.map_add, hllin.map_smul, hllin.map_smul],
  sorry
end

lemma subset_frontier_of_extreme (hAB : extreme_set A B) (hBA : B ⊂ A) :
  B ⊆ frontier A :=
begin
  rintro x hxB,
  obtain ⟨y, hyA, hyB⟩ := nonempty_of_ssubset hBA,
  rw frontier_eq_closure_inter_closure,
  use subset_closure (hBA.1 hxB),
  rw mem_closure_iff_seq_limit,
  let z : ℕ → E := λ n, (1 + 1/n.succ : ℝ) • x - (1/n.succ : ℝ) • y,
  use z,
  split,
  {
    rintro n hzn,
    --have := hAB.2 y (f n) hyA hfn x hxB,
    refine hyB (hAB.2 y (z n) hyA hzn x hxB ⟨1/(↑n + 1)/(1/(↑n + 1) + 1), 1/(1/(↑n + 1) + 1), _, _, _, _⟩
      _ _).1,
    { exact le_of_lt (div_pos nat.one_div_pos_of_nat (add_pos nat.one_div_pos_of_nat (by linarith))),
    },
    {
      exact le_of_lt (one_div_pos.2 (add_pos nat.one_div_pos_of_nat (by linarith))),
    },
    {
      rw [←add_div, div_self],
      exact (ne_of_gt (add_pos nat.one_div_pos_of_nat (by linarith))),
    },
    {
      sorry,
    },
    {
      rintro rfl,
      exact hyB hxB,
    },
    {
      rintro h,
      suffices h : 1 • x = 1 • y,
      {
        simp at h,
        rw h at hxB,
        exact hyB hxB,
      },
      suffices h : (1/n.succ : ℝ) • x = (1/n.succ : ℝ) • y,
      {
        sorry
      },
      sorry
      /-calc
        (1/n.succ : ℝ) • x
            = -(1 • x) + (1 • x + (1 / ↑(n.succ)) • x - (1 / ↑(n.succ)) • y) + (1 / ↑(n.succ)) • y
            : by sorry--ring_nf
        ... = -(1 • x) + ((1 + 1 / ↑(n.succ)) • x - (1 / ↑(n.succ)) • y) + (1 / ↑(n.succ)) • y
            : by sorry
        ... = -(1 • x) + z n + (1 / ↑(n.succ)) • y
            : by sorry
        ... = -(1 • x) + x + (1 / ↑(n.succ)) • y
            : by rw h
        ... = (1 / ↑(n.succ)) • y : by rw sub_self _,-/
      /-calc
        1 • x = (↑n.succ/(n.succ : ℝ)) • x
          : nat.div_self nat.succ_pos'
        ... = (n.succ : ℝ) • (1/n.succ : ℝ) • x-/
    },
  },
  sorry
end

lemma mem_extreme_set_iff_mem_frontier :
  (∃ B : set E, extreme_set A B ∧ B ⊂ A ∧ x ∈ B) ↔ x ∈ A ∧ x ∈ frontier A :=
begin
  use λ ⟨B, hAB, hBA, hxB⟩, ⟨hAB.1 hxB, subset_frontier_of_extreme hAB hBA hxB⟩,
  rintro ⟨hxA, hxfA⟩,
  sorry
end




--probably belongs in the mathlib file of convex hulls
lemma subset_of_convex_hull_eq_convex_hull_of_linearly_independent {X Y : finset E}
  (hX : affine_independent ℝ (λ p, p : (X : set E) → E))
  (h : convex_hull ↑X = convex_hull (Y : set E)) :
  X ⊆ Y :=
begin
  rintro x hx,
  have hxextreme := extreme_to_convex_hull_of_affine_independent hx hX,
  rw h at hxextreme,
  exact_mod_cast mem_of_extreme_to_convex_hull hxextreme,
end

--Keep two linearly_independent in the name?
lemma eq_of_convex_hull_eq_convex_hull_of_linearly_independent
  {X Y : finset E}
  (hX : affine_independent ℝ (λ p, p : (X : set E) → E))
  (hY : affine_independent ℝ (λ p, p : (Y : set E) → E))
  (h : convex_hull (X : set E) = convex_hull (Y : set E)) :
  X = Y :=
finset.subset.antisymm
  (subset_of_convex_hull_eq_convex_hull_of_linearly_independent hX h)
  (subset_of_convex_hull_eq_convex_hull_of_linearly_independent hY h.symm)

end affine
