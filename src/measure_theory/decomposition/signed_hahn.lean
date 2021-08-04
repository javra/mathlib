/-
Copyright (c) 2021 Kexing Ying. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kexing Ying
-/
import measure_theory.vector_measure
import order.symm_diff

/-!
# Hahn decomposition

This file prove the Hahn decomposition theorem (signed version).

## Main results

* `signed_measure.exists_disjoint_positive_negative_union_eq` : the Hahn decomposition theorem.
* `signed_measure.exists_subset_restrict_nonpos` : A measurable set of negative measure contains at least
  one negative subset.

## Notation

We use the notations `0 ≤[i] v` and `v ≤[i] 0` to denote the usual definitions of a set `i`
being positive/negative with respect to the signed measure `v`.

## Tags

Hahn decomposition theorem
-/

noncomputable theory
open_locale classical big_operators nnreal ennreal

variables {α β : Type*} [measurable_space α]
variables {M : Type*} [add_comm_monoid M] [topological_space M] [ordered_add_comm_monoid M]

namespace measure_theory

namespace signed_measure

open filter vector_measure

variables {s : signed_measure α} {i j : set α}

section exists_subset_restrict_nonpos

/-! ### exists_subset_restrict_nonpos

In this section we will prove that a set `i` whose measure is negative contains a negative subset
`j` with respect to the signed measure `s` (i.e. `s ≤[j] 0`), whose measure is negative. This lemma
is used to prove the Hahn decomposition theorem.

To prove this lemma, we will construct a sequence of measurable sets $(A_n)_{n \in \mathbb{N}}$,
such that, for all $n$, $A_{n + 1} \subseteq i \setminus \bigcup_{k \le n} A_k$ and
$\frac{1}{a_n + 1} < s(A_{n + 1})$ for some sequence $a_n \to \infty$.

This sequence does not necessarily exist. However, if this sequence terminates, that is there
does not exists any sets satisfying the property, the last $A_n$ will be a negative subset of
negative measure, hence proving our claim.

In the case that the sequence does not terminate, it is easy to see that
$i \setminus \bigcup_{k = 0}^\infty A_k$ is the required set.

To implement this in Lean, we define several auxilary definitions.

- given sets `i`, `j` and the natural number `n`, `exists_one_div_lt s i j n` is the property that
  there exists a measurable set `k ⊆ i \ j` such that `1 / (n + 1) < s k`.
- given sets `i`, `j` and that `i \ j` is not negative, `find_exists_one_div_lt s i j` is the
  least natural number `n` such that `exists_one_div_lt s i j n`. This definition provide the
  sequence $(a_n)$ in the proof as described above.
- given sets `i`, `j` and that `i \ j` is not negative, `some_exists_one_div_lt` chooses the set
  `k` from `exists_one_div_lt s i j (find_exists_one_div_lt s i j)`.
- lastly, given set `i`, `restrict_nonpos_seq s i` is the sequence of sets defined inductively where
  `restrict_nonpos_seq s i 0 = some_exists_one_div_lt s i ∅` and
  `restrict_nonpos_seq s i (n + 1) = some_exists_one_div_lt s i ⋃ k ≤ n, restrict_nonpos_seq k`.
  This definition representing the sequence $(A_n)$ in the proof as described above.

With these definitions, we are able consider the case where the sequence terminates seperately,
allowing us to prove `exists_subset_restrict_nonpos`.
-/

private def exists_one_div_lt (s : signed_measure α) (i j : set α) (n : ℕ) : Prop :=
∃ k : set α, k ⊆ i \ j ∧ measurable_set k ∧ (1 / (n + 1) : ℝ) < s k

private lemma exists_nat_one_div_lt_measure_of_not_negative (hi : ¬ s ≤[i \ j] 0) :
  ∃ (n : ℕ), exists_one_div_lt s i j n :=
let ⟨k, hj₁, hj₂, hj⟩ := exists_pos_measure_of_not_restrict_le_zero s hi in
let ⟨n, hn⟩ := exists_nat_one_div_lt hj in ⟨n, k, hj₂, hj₁, hn⟩

private def find_exists_one_div_lt (s : signed_measure α) (i j : set α) : ℕ :=
if hi : ¬ s ≤[i \ j] 0 then nat.find (exists_nat_one_div_lt_measure_of_not_negative hi) else 0

private lemma find_exists_one_div_lt_spec (hi : ¬ s ≤[i \ j] 0) :
  exists_one_div_lt s i j (find_exists_one_div_lt s i j) :=
begin
  rw [find_exists_one_div_lt, dif_pos hi],
  convert nat.find_spec _,
end

private lemma find_exists_one_div_lt_min (hi : ¬ s ≤[i \ j] 0) {m : ℕ}
  (hm : m < find_exists_one_div_lt s i j) : ¬ exists_one_div_lt s i j m :=
begin
  rw [find_exists_one_div_lt, dif_pos hi] at hm,
  exact nat.find_min _ hm
end

private def some_exists_one_div_lt (s : signed_measure α) (i j : set α) : set α :=
if hi : ¬ s ≤[i \ j] 0 then classical.some (find_exists_one_div_lt_spec hi) else ∅

private lemma some_exists_one_div_lt_spec (hi : ¬ s ≤[i \ j] 0) :
  (some_exists_one_div_lt s i j) ⊆ i \ j ∧ measurable_set (some_exists_one_div_lt s i j) ∧
  (1 / (find_exists_one_div_lt s i j + 1) : ℝ) < s (some_exists_one_div_lt s i j) :=
begin
  rw [some_exists_one_div_lt, dif_pos hi],
  exact classical.some_spec (find_exists_one_div_lt_spec hi),
end

private lemma some_exists_one_div_lt_subset : some_exists_one_div_lt s i j ⊆ i \ j :=
begin
  by_cases hi : ¬ s ≤[i \ j] 0,
  { exact let ⟨h, _⟩ := some_exists_one_div_lt_spec hi in h },
  { rw [some_exists_one_div_lt, dif_neg hi],
    exact set.empty_subset _ },
end

private lemma some_exists_one_div_lt_subset' : some_exists_one_div_lt s i j ⊆ i :=
set.subset.trans some_exists_one_div_lt_subset (set.diff_subset _ _)

private lemma some_exists_one_div_lt_measurable_set :
  measurable_set (some_exists_one_div_lt s i j) :=
begin
  by_cases hi : ¬ s ≤[i \ j] 0,
  { exact let ⟨_, h, _⟩ := some_exists_one_div_lt_spec hi in h },
  { rw [some_exists_one_div_lt, dif_neg hi],
    exact measurable_set.empty }
end

private lemma some_exists_one_div_lt_lt (hi : ¬ s ≤[i \ j] 0) :
  (1 / (find_exists_one_div_lt s i j + 1) : ℝ) < s (some_exists_one_div_lt s i j) :=
let ⟨_, _, h⟩ := some_exists_one_div_lt_spec hi in h

private def restrict_nonpos_seq (s : signed_measure α) (i : set α) : ℕ → set α
| 0 := some_exists_one_div_lt s i ∅
| (n + 1) := some_exists_one_div_lt s i ⋃ k ≤ n,
  have k < n + 1 := nat.lt_succ_iff.mpr H,
  restrict_nonpos_seq k

private lemma restrict_nonpos_seq_succ (n : ℕ) :
  restrict_nonpos_seq s i n.succ =
  some_exists_one_div_lt s i ⋃ k ≤ n, restrict_nonpos_seq s i k :=
by rw restrict_nonpos_seq

private lemma restrict_nonpos_seq_subset (n : ℕ) :
  restrict_nonpos_seq s i n ⊆ i :=
begin
  cases n;
  { rw restrict_nonpos_seq, exact some_exists_one_div_lt_subset' }
end

private lemma restrict_nonpos_seq_lt
  (n : ℕ) (hn :¬ s ≤[i \ ⋃ l ≤ n, restrict_nonpos_seq s i l] 0) :
  (1 / (find_exists_one_div_lt s i (⋃ k ≤ n, restrict_nonpos_seq s i k) + 1) : ℝ)
  < s (restrict_nonpos_seq s i n.succ) :=
begin
  rw restrict_nonpos_seq_succ,
  apply some_exists_one_div_lt_lt hn,
end

private lemma measure_of_restrict_nonpos_seq (hi₂ : ¬ s ≤[i] 0)
  (n : ℕ) (hn : ¬ s ≤[i \ ⋃ k < n, restrict_nonpos_seq s i k] 0) :
  0 < s (restrict_nonpos_seq s i n) :=
begin
  cases n,
  { rw restrict_nonpos_seq, rw ← @set.diff_empty _ i at hi₂,
    rcases some_exists_one_div_lt_spec hi₂ with ⟨_, _, h⟩,
    exact (lt_trans nat.one_div_pos_of_nat h) },
  { rw restrict_nonpos_seq_succ,
    have h₁ : ¬ s ≤[i \ ⋃ (k : ℕ) (H : k ≤ n), restrict_nonpos_seq s i k] 0,
    { apply not_restrict_le_zero_subset _ hn,
      { apply set.diff_subset_diff_right,
        intros x,
        simp_rw [set.mem_Union],
        rintro ⟨n, hn₁, hn₂⟩,
        exact ⟨n, nat.lt_succ_iff.mpr hn₁, hn₂⟩ },
      { convert measurable_of_not_restrict_le_zero _ hn,
        exact funext (λ x, by rw nat.lt_succ_iff) } },
    rcases some_exists_one_div_lt_spec h₁ with ⟨_, _, h⟩,
    exact (lt_trans nat.one_div_pos_of_nat h) }
end

private lemma restrict_nonpos_seq_measurable_set (n : ℕ) :
  measurable_set (restrict_nonpos_seq s i n) :=
begin
  cases n,
  { rw restrict_nonpos_seq,
    exact some_exists_one_div_lt_measurable_set },
  { rw restrict_nonpos_seq,
    exact some_exists_one_div_lt_measurable_set }
end

private lemma restrict_nonpos_seq_disjoint' {n m : ℕ} (h : n < m) :
  restrict_nonpos_seq s i n ∩ restrict_nonpos_seq s i m = ∅ :=
begin
  rw set.eq_empty_iff_forall_not_mem,
  rintro x ⟨hx₁, hx₂⟩,
  cases m, linarith,
  { rw restrict_nonpos_seq at hx₂,
    exact (some_exists_one_div_lt_subset hx₂).2
      (set.mem_Union.2 ⟨n, set.mem_Union.2 ⟨nat.lt_succ_iff.mp h, hx₁⟩⟩) }
end

private lemma restrict_nonpos_seq_disjoint : pairwise (disjoint on (restrict_nonpos_seq s i)) :=
begin
  intros n m h,
  rcases lt_or_gt_of_ne h with (h | h),
  { intro x,
    rw [set.inf_eq_inter, restrict_nonpos_seq_disjoint' h],
    exact id },
  { intro x,
    rw [set.inf_eq_inter, set.inter_comm, restrict_nonpos_seq_disjoint' h],
    exact id }
end

private lemma exists_subset_restrict_nonpos' (hi₁ : measurable_set i) (hi₂ : s i < 0)
  (hn : ¬ ∀ n : ℕ, ¬ s ≤[i \ ⋃ l < n, restrict_nonpos_seq s i l] 0) :
  ∃ j : set α, measurable_set j ∧ j ⊆ i ∧ s ≤[j] 0 ∧ s j < 0 :=
begin
  by_cases s ≤[i] 0,
  { exact ⟨i, hi₁, set.subset.refl _, h, hi₂⟩ },
  { push_neg at hn,
    set k := nat.find hn with hk₁,
    have hk₂ : s ≤[i \ ⋃ l < k, restrict_nonpos_seq s i l] 0 := nat.find_spec hn,
    have hmeas : measurable_set (⋃ (l : ℕ) (H : l < k), restrict_nonpos_seq s i l) :=
      (measurable_set.Union $ λ _, measurable_set.Union_Prop
        (λ _, restrict_nonpos_seq_measurable_set _)),
    refine ⟨i \ ⋃ l < k, restrict_nonpos_seq s i l, hi₁.diff hmeas, set.diff_subset _ _, hk₂, _⟩,
    rw [of_diff hmeas hi₁, s.of_disjoint_Union_nat],
    { have h₁ : ∀ l < k, 0 ≤ s (restrict_nonpos_seq s i l),
      { intros l hl,
        refine le_of_lt (measure_of_restrict_nonpos_seq h _ ((not_restrict_le_zero_subset _
          (nat.find_min hn hl) (set.subset.refl _)) (hi₁.diff _))),
        exact (measurable_set.Union $ λ _, measurable_set.Union_Prop
          (λ _, restrict_nonpos_seq_measurable_set _)) },
      suffices : 0 ≤ ∑' (l : ℕ), s (⋃ (H : l < k), restrict_nonpos_seq s i l),
      { rw sub_neg,
        exact lt_of_lt_of_le hi₂ this },
      refine tsum_nonneg _,
      intro l, by_cases l < k,
      { convert h₁ _ h,
        ext x,
        rw [set.mem_Union, exists_prop, and_iff_right_iff_imp],
        exact λ _, h },
      { convert le_of_eq s.empty.symm,
        ext, simp only [exists_prop, set.mem_empty_eq, set.mem_Union, not_and, iff_false],
        exact λ h', false.elim (h h') } },
    { intro, exact measurable_set.Union_Prop (λ _, restrict_nonpos_seq_measurable_set _) },
    { intros a b hab x hx,
      simp only [exists_prop, set.mem_Union, set.mem_inter_eq, set.inf_eq_inter] at hx,
      exact let ⟨⟨_, hx₁⟩, _, hx₂⟩ := hx in restrict_nonpos_seq_disjoint a b hab ⟨hx₁, hx₂⟩ },
    { apply set.Union_subset,
      intros a x,
      simp only [and_imp, exists_prop, set.mem_Union],
      intros _ hx,
      exact restrict_nonpos_seq_subset _ hx },
    { apply_instance } }
end .

/-- A measurable set of negative measure has a negative subset of negative measure. -/
theorem exists_subset_restrict_nonpos (hi : s i < 0) :
  ∃ j : set α, measurable_set j ∧ j ⊆ i ∧ s ≤[j] 0 ∧ s j < 0 :=
begin
  have hi₁ :  measurable_set i :=
    classical.by_contradiction (λ h, ne_of_lt hi $ s.not_measurable h),
  by_cases s ≤[i] 0,
  { exact ⟨i, hi₁, set.subset.refl _, h, hi⟩ },
  { by_cases hn : ∀ n : ℕ, ¬ s ≤[i \ ⋃ l < n, restrict_nonpos_seq s i l] 0,
    { set A := i \ ⋃ l, restrict_nonpos_seq s i l with hA,
      set bdd : ℕ → ℕ := λ n,
        find_exists_one_div_lt s i (⋃ k ≤ n, restrict_nonpos_seq s i k) with hbdd,

      have hn' : ∀ n : ℕ, ¬ s ≤[i \ ⋃ l ≤ n, restrict_nonpos_seq s i l] 0,
      { intro n,
        convert hn (n + 1);
        { ext l,
          simp only [exists_prop, set.mem_Union, and.congr_left_iff],
          exact λ _, nat.lt_succ_iff.symm } },
      have h₁ : s i = s A + ∑' l, s (restrict_nonpos_seq s i l),
      { rw [hA, ← s.of_disjoint_Union_nat, add_comm, of_add_of_diff],
        exact measurable_set.Union (λ _, restrict_nonpos_seq_measurable_set _),
        exacts [hi₁, set.Union_subset (λ _, restrict_nonpos_seq_subset _), λ _,
                restrict_nonpos_seq_measurable_set _, restrict_nonpos_seq_disjoint] },
      have h₂ : s A ≤ s i,
      { rw h₁,
        apply le_add_of_nonneg_right,
        exact tsum_nonneg (λ n, le_of_lt (measure_of_restrict_nonpos_seq h _ (hn n))) },
      have h₃' : summable (λ n, (1 / (bdd n + 1) : ℝ)),
      { have : summable (λ l, s (restrict_nonpos_seq s i l)),
        { exact has_sum.summable (s.m_Union (λ _, restrict_nonpos_seq_measurable_set _)
          restrict_nonpos_seq_disjoint) },
        refine summable_of_nonneg_of_le _ _ (summable.comp_injective this nat.succ_injective),
        { intro _, exact le_of_lt nat.one_div_pos_of_nat },
        { intro n, exact le_of_lt (restrict_nonpos_seq_lt n (hn' n)) } },
      have h₃ : tendsto (λ n, (bdd n : ℝ) + 1) at_top at_top,
      { simp only [one_div] at h₃',
        exact summable.tendsto_top_of_pos h₃' (λ n, nat.cast_add_one_pos (bdd n)) },
      have h₄ : tendsto (λ n, (bdd n : ℝ)) at_top at_top,
      { convert at_top.tendsto_at_top_add_const_right (-1) h₃, simp },

      refine ⟨A, _, set.diff_subset _ _, _, _⟩,
      { exact hi₁.diff (measurable_set.Union (λ _, restrict_nonpos_seq_measurable_set _)) },
      { by_contra hnn,
        have hA₁ : measurable_set A := measurable_of_not_restrict_le_zero _ hnn,
        rw restrict_le_restrict_iff _ _ hA₁ at hnn, push_neg at hnn,
        obtain ⟨E, hE₁, hE₂, hE₃⟩ := hnn,
        have : ∃ k, 1 ≤ bdd k ∧ 1 / (bdd k : ℝ) < s E,
        { rw tendsto_at_top_at_top at h₄,
          obtain ⟨k, hk⟩ := h₄ (max (1 / s E + 1) 1),
          refine ⟨k, _, _⟩,
          { have hle := le_of_max_le_right (hk k le_rfl),
            norm_cast at hle,
            exact hle },
          { have : 1 / s E < bdd k,
            { linarith [le_of_max_le_left (hk k le_rfl)] {restrict_type := ℝ} },
            rw one_div at this ⊢,
            rwa inv_lt (lt_trans (inv_pos.2 hE₃) this) hE₃ } },
        obtain ⟨k, hk₁, hk₂⟩ := this,
        have hA' : A ⊆ i \ ⋃ l ≤ k, restrict_nonpos_seq s i l,
        { rw hA,
          apply set.diff_subset_diff_right,
          intro x, simp only [set.mem_Union],
          rintro ⟨n, _, hn₂⟩,
          exact ⟨n, hn₂⟩ },
        refine find_exists_one_div_lt_min (hn' k)
          (buffer.lt_aux_2 hk₁) ⟨E, set.subset.trans hE₂ hA', hE₁, _⟩,
        convert hk₂, norm_cast,
        exact nat.sub_add_cancel hk₁ },
      { exact lt_of_le_of_lt h₂ hi } },
    { exact exists_subset_restrict_nonpos' hi₁ hi hn } }
end .

end exists_subset_restrict_nonpos

/-- The set of measures of the set of measurable negative sets. -/
def measure_of_negatives (s : signed_measure α) : set ℝ :=
  s '' { B | measurable_set B ∧ s ≤[B] 0 }

lemma zero_mem_measure_of_negatives : (0 : ℝ) ∈ s.measure_of_negatives :=
⟨∅, ⟨measurable_set.empty, restrict_empty_le_zero _⟩, s.empty⟩

lemma bdd_below_measure_of_negatives :
  bdd_below s.measure_of_negatives :=
begin
  simp_rw [bdd_below, set.nonempty, lower_bounds, set.mem_set_of_eq],
  by_contra, push_neg at h,
  have h' : ∀ n : ℕ, ∃ y : ℝ, y ∈ s.measure_of_negatives ∧ y < -n := λ n, h (-n),
  choose f hf using h',
  have hf' : ∀ n : ℕ, ∃ B ∈ { B | measurable_set B ∧ s ≤[B] 0 }, s B < -n,
  { intro n,
    rcases hf n with ⟨⟨B, hB₁, hB₂⟩, hlt⟩,
    exact ⟨B, hB₁, hB₂.symm ▸ hlt⟩ },
  choose B hB using hf',
  have hmeas : ∀ n, measurable_set (B n) := λ n, let ⟨h, _⟩ := (hB n).1 in h,
  set A := ⋃ n, B n with hA,
  have hfalse : ∀ n : ℕ, s A ≤ -n,
  { intro n,
    refine le_trans _ (le_of_lt (hB n).2),
    rw [hA, ← set.diff_union_of_subset (set.subset_Union _ n),
        of_union (disjoint.comm.1 set.disjoint_diff) _ (hmeas n)],
    { refine add_le_of_nonpos_left _,
      have : s ≤[A] 0 :=
        restrict_le_restrict_Union _ _ hmeas (λ m, let ⟨_, h⟩ := (hB m).1 in h),
      refine nonpos_of_restrict_le_zero _ (restrict_le_zero_subset _ _ this (set.diff_subset _ _)),
      exact measurable_set.Union hmeas },
    { apply_instance },
    { exact (measurable_set.Union hmeas).diff (hmeas n) } },
  suffices : ¬ ∀ n : ℕ, s A ≤ -n,
  { exact this hfalse },
  push_neg,
  rcases exists_nat_gt (-(s A)) with ⟨n, hn⟩,
  exact ⟨n, neg_lt.1 hn⟩,
end

/-- **The Hahn decomposition thoerem**: Given a signed measure `s`, there exist
disjoint measurable sets `i`, `j` such that `i` is positive, `j` is negative
and `i ∪ j = set.univ`.  -/
theorem exists_disjoint_positive_negative_union_eq (s : signed_measure α) :
  ∃ i j : set α, measurable_set i ∧ 0 ≤[i] s ∧ measurable_set j ∧ s ≤[j] 0 ∧
  disjoint i j ∧ i ∪ j = set.univ :=
begin
  obtain ⟨f, _, hf₂, hf₁⟩ := exists_seq_tendsto_Inf
    ⟨0, @zero_mem_measure_of_negatives _ _ s⟩ bdd_below_measure_of_negatives,

  choose B hB using hf₁,
  have hB₁ : ∀ n, measurable_set (B n) := λ n, let ⟨h, _⟩ := (hB n).1 in h,
  have hB₂ : ∀ n, s ≤[B n] 0 := λ n, let ⟨_, h⟩ := (hB n).1 in h,

  set A := ⋃ n, B n with hA,
  have hA₁ : measurable_set A := measurable_set.Union hB₁,
  have hA₂ : s ≤[A] 0 := restrict_le_restrict_Union _ _ hB₁ hB₂,
  have hA₃ : s A = Inf s.measure_of_negatives,
  { apply has_le.le.antisymm,
    { refine le_of_tendsto_of_tendsto tendsto_const_nhds hf₂ (eventually_of_forall _),
      intro n,
      rw [← (hB n).2, hA, ← set.diff_union_of_subset (set.subset_Union _ n),
      of_union (disjoint.comm.1 set.disjoint_diff) _ (hB₁ n)],
      { refine add_le_of_nonpos_left _,
        have : s ≤[A] 0 :=
          restrict_le_restrict_Union _ _ hB₁ (λ m, let ⟨_, h⟩ := (hB m).1 in h),
        refine nonpos_of_restrict_le_zero _
          (restrict_le_zero_subset _ _ this (set.diff_subset _ _)),
        exact measurable_set.Union hB₁ },
      { apply_instance },
      { exact (measurable_set.Union hB₁).diff (hB₁ n) } },
    { exact real.Inf_le _ bdd_below_measure_of_negatives ⟨A, ⟨hA₁, hA₂⟩, rfl⟩ } },

  refine ⟨Aᶜ, A, hA₁.compl, _, hA₁, hA₂,
          disjoint_compl_left, (set.union_comm A Aᶜ) ▸ set.union_compl_self A⟩,
  rw restrict_le_restrict_iff _ _ hA₁.compl,
  intros C hC hC₁,
  by_contra hC₂, push_neg at hC₂,
  rcases exists_subset_restrict_nonpos hC₂ with ⟨D, hD₁, hD, hD₂, hD₃⟩,

  have : s (A ∪ D) < Inf s.measure_of_negatives,
  { rw [← hA₃, of_union (set.disjoint_of_subset_right (set.subset.trans hD hC₁)
        disjoint_compl_right) hA₁ hD₁],
    linarith, apply_instance },
  refine not_le.2 this _,
  refine real.Inf_le _ bdd_below_measure_of_negatives ⟨A ∪ D, ⟨_, _⟩, rfl⟩,
  { exact hA₁.union hD₁ },
  { exact restrict_le_restrict_union _ _ hA₁ hA₂ hD₁ hD₂ }
end

/-- Alternative formulation of `exists_disjoint_positive_negative_union_eq` using complements. -/
lemma exists_compl_positive_negative (s : signed_measure α) :
  ∃ i : set α, measurable_set i ∧ 0 ≤[i] s ∧ s ≤[iᶜ] 0 :=
begin
  obtain ⟨i, j, hi₁, hi₂, _, hj₂, hdisj, huniv⟩ :=
    s.exists_disjoint_positive_negative_union_eq,
  refine ⟨i, hi₁, hi₂, _⟩,
  rw [set.compl_eq_univ_diff, ← huniv,
      set.union_diff_cancel_left (set.disjoint_iff.mp hdisj)],
  exact hj₂,
end

/-- The symmetric difference of two Hahn decompositions have measure zero. -/
lemma of_symm_diff_compl_positive_negative {s : signed_measure α}
  {i j : set α} (hi : measurable_set i) (hj : measurable_set j)
  (hi' : 0 ≤[i] s ∧ s ≤[iᶜ] 0) (hj' : 0 ≤[j] s ∧ s ≤[jᶜ] 0) :
  s (i Δ j) = 0 ∧ s (iᶜ Δ jᶜ) = 0 :=
begin
  rw [restrict_le_restrict_iff s 0, restrict_le_restrict_iff 0 s] at hi' hj',
  split,
  { rw [symm_diff_def, set.diff_eq_compl_inter, set.diff_eq_compl_inter,
        set.sup_eq_union, of_union,
        le_antisymm (hi'.2 (hi.compl.inter hj) (set.inter_subset_left _ _))
          (hj'.1 (hi.compl.inter hj) (set.inter_subset_right _ _)),
        le_antisymm (hj'.2 (hj.compl.inter hi) (set.inter_subset_left _ _))
          (hi'.1 (hj.compl.inter hi) (set.inter_subset_right _ _)),
        zero_apply, zero_apply, zero_add],
    { exact set.disjoint_of_subset_left (set.inter_subset_left _ _)
        (set.disjoint_of_subset_right (set.inter_subset_right _ _)
        (disjoint.comm.1 (is_compl.disjoint is_compl_compl))) },
    { exact hj.compl.inter hi },
    { exact hi.compl.inter hj } },
  { rw [symm_diff_def, set.diff_eq_compl_inter, set.diff_eq_compl_inter,
        compl_compl, compl_compl, set.sup_eq_union, of_union,
        le_antisymm (hi'.2 (hj.inter hi.compl) (set.inter_subset_right _ _))
          (hj'.1 (hj.inter hi.compl) (set.inter_subset_left _ _)),
        le_antisymm (hj'.2 (hi.inter hj.compl) (set.inter_subset_right _ _))
          (hi'.1 (hi.inter hj.compl) (set.inter_subset_left _ _)),
        zero_apply, zero_apply, zero_add],
    { exact set.disjoint_of_subset_left (set.inter_subset_left _ _)
        (set.disjoint_of_subset_right (set.inter_subset_right _ _)
        (is_compl.disjoint is_compl_compl)) },
    { exact hj.inter hi.compl },
    { exact hi.inter hj.compl } },
  all_goals { measurability },
end

end signed_measure

end measure_theory
