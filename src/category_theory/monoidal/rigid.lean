/-
Copyright (c) 2021 Jakob von Raumer. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jakob von Raumer
-/

import category_theory.monoidal.category

open category_theory

universes v v₁ v₂ v₃ u u₁ u₂ u₃
noncomputable theory

namespace category_theory

variables {C : Type u₁} [category.{v₁} C] [monoidal_category C]

/- An exact pairing is a pair of objects `X Y : C` which admit
  a coevaluation and evaluation morphism which fulfill two triangle equalities. -/
class exact_pairing (X Y : C) :=
  (coevaluation [] : 𝟙_ C ⟶ X ⊗ Y)
  (evaluation [] : Y ⊗ X ⟶ 𝟙_ C)
  (coevaluation_evaluation' [] :
    (𝟙 Y ⊗ coevaluation) ≫ (α_ _ _ _).inv ≫ (evaluation ⊗ 𝟙 Y)
    = (ρ_ Y).hom ≫ (λ_ Y).inv . obviously)
  (evaluation_coevaluation' [] :
    (coevaluation ⊗ 𝟙 X) ≫ (α_ _ _ _).hom ≫ (𝟙 X ⊗ evaluation)
    = (λ_ X).hom ≫ (ρ_ X).inv . obviously)

open exact_pairing

notation `η_` := exact_pairing.coevaluation
notation `ε_` := exact_pairing.evaluation

restate_axiom coevaluation_evaluation'
attribute [reassoc, simp] exact_pairing.coevaluation_evaluation
restate_axiom evaluation_coevaluation'
attribute [reassoc, simp] exact_pairing.evaluation_coevaluation

instance exact_pairing_unit : exact_pairing (𝟙_ C) (𝟙_ C) :=
{ coevaluation := (ρ_ _).inv,
  evaluation := (ρ_ _).hom,
  coevaluation_evaluation' := by {
    rw[monoidal_category.triangle_assoc_comp_right,
      monoidal_category.unitors_inv_equal,
      monoidal_category.unitors_equal], simp },
  evaluation_coevaluation' := by {
    rw[monoidal_category.triangle_assoc_comp_right_inv_assoc,
      monoidal_category.unitors_inv_equal,
      monoidal_category.unitors_equal], simp } }

instance exact_pairing_tensor (W X Y Z : C) [WX : exact_pairing W X] [YZ : exact_pairing Y Z] :
  exact_pairing (W ⊗ Y) (Z ⊗ X) :=
{ coevaluation := WX.coevaluation ≫ (𝟙 W ⊗ (λ_ X).inv) ≫ (𝟙 W ⊗ YZ.coevaluation ⊗ 𝟙 X)
    ≫ (𝟙 W ⊗ (α_ Y Z X).hom) ≫ (α_ W Y (Z ⊗ X)).inv,
  evaluation := (α_ (Z ⊗ X) W Y).inv ≫ ((α_ Z X W).hom ⊗ 𝟙 Y)
    ≫ ((𝟙 Z ⊗ WX.evaluation) ⊗ 𝟙 Y) ≫ ((ρ_ Z).hom ⊗ 𝟙 Y) ≫ YZ.evaluation,
  coevaluation_evaluation' := sorry,
  evaluation_coevaluation' := sorry }

/- A class of objects which have a right dual, -/
class has_right_dual (X : C) :=
  (right_dual : C)
  [exact : exact_pairing X right_dual]

/- ... and a class of objects with have a left dual.-/
class has_left_dual (Y : C) :=
  (left_dual : C)
  [exact : exact_pairing left_dual Y]

attribute [instance] has_right_dual.exact
attribute [instance] has_left_dual.exact

open exact_pairing has_right_dual has_left_dual monoidal_category

reserve prefix `*^`:1025
notation `*^` X := left_dual X
reserve postfix `^*`:1025
notation X `^*` := right_dual X

instance has_right_dual_unit : has_right_dual (𝟙_ C) :=
{ right_dual := 𝟙_ C }

instance has_left_dual_unit : has_left_dual (𝟙_ C) :=
{ left_dual := 𝟙_ C }

instance has_right_dual_left_dual {X : C} [has_left_dual X] : has_right_dual (*^X) :=
{ right_dual := X }

instance has_left_dual_right_dual {X : C} [has_right_dual X] : has_left_dual (X ^*) :=
{ left_dual := X }

@[simp]
lemma left_dual_right_dual {X : C} [has_right_dual X] : *^(X^*) = X := rfl

@[simp]
lemma right_dual_left_dual {X : C} [has_left_dual X] : (*^X)^* = X := rfl

def right_adjoint_mate {X Y : C} [has_right_dual X] [has_right_dual Y] (f : X ⟶ Y) : Y^* ⟶ X^* :=
(ρ_ _).inv ≫ (𝟙 _ ⊗ η_ _ _) ≫ (𝟙 _ ⊗ (f ⊗ 𝟙 _)) ≫ (α_ _ _ _).inv ≫ ((ε_ _ _) ⊗ 𝟙 _) ≫ (λ_ _).hom

def left_adjoint_mate {X Y : C} [has_left_dual X] [has_left_dual Y] (f : X ⟶ Y) : *^Y ⟶ *^X :=
(λ_ _).inv ≫ (η_ *^X X ⊗ 𝟙 _) ≫ ((𝟙 _ ⊗ f) ⊗ 𝟙 _) ≫ (α_ _ _ _).hom ≫ (𝟙 _ ⊗ ε_ _ _) ≫ (ρ_ _).hom

notation f `^*` := right_adjoint_mate f
notation `*^` f := left_adjoint_mate f

@[simp] --Do we want this to be simp?
theorem right_adjoint_mate_id {X : C} [has_right_dual X] : (𝟙 X)^* = 𝟙 (X^*) :=
by simp only [right_adjoint_mate, monoidal_category.tensor_id, category.id_comp,
  coevaluation_evaluation_assoc, category.comp_id, iso.inv_hom_id]

@[simp] theorem left_adjoint_mate_id {X : C} [has_left_dual X] : *^(𝟙 X) = 𝟙 (*^X) :=
by simp only [left_adjoint_mate, monoidal_category.tensor_id, category.id_comp,
  evaluation_coevaluation_assoc, category.comp_id, iso.inv_hom_id]

theorem right_adjoint_mate_comp {X Y Z : C} [has_right_dual X]
  [has_right_dual Y] {f : X ⟶ Y} {g : X^* ⟶ Z} :
  f^* ≫ g
  = (ρ_ Y^*).inv ≫ (𝟙 _ ⊗ η_ X X^*) ≫ (𝟙 _ ⊗ f ⊗ g)
    ≫ (α_ Y^* Y Z).inv ≫ (ε_ Y Y^* ⊗ 𝟙 _) ≫ (λ_ Z).hom :=
begin
  dunfold right_adjoint_mate,
  rw [category.assoc, category.assoc, associator_inv_naturality_assoc, associator_inv_naturality_assoc,
    ←tensor_id_comp_id_tensor g, category.assoc, category.assoc, category.assoc, category.assoc,
    id_tensor_comp_tensor_id_assoc, ←left_unitor_naturality, tensor_id_comp_id_tensor_assoc],
end

theorem left_adjoint_mate_comp {X Y Z : C} [has_left_dual X] [has_left_dual Y]
  {f : X ⟶ Y} {g : *^X ⟶ Z} :
  *^f ≫ g
  = (λ_ _).inv ≫ (η_ *^X X ⊗ 𝟙 _) ≫ ((g ⊗ f) ⊗ 𝟙 _)
    ≫ (α_ _ _ _).hom ≫ (𝟙 _ ⊗ ε_ _ _) ≫ (ρ_ _).hom :=
begin
  dunfold left_adjoint_mate,
  rw [category.assoc, category.assoc, associator_naturality_assoc, associator_naturality_assoc,
  ←id_tensor_comp_tensor_id _ g, category.assoc, category.assoc, category.assoc, category.assoc,
  tensor_id_comp_id_tensor_assoc, ←right_unitor_naturality, id_tensor_comp_tensor_id_assoc],
end

/- The composition of adjoint mates is the adjoint mate of the composition. -/
@[reassoc]
lemma comp_right_adjoint_mate {X Y Z : C}
  [has_right_dual X] [has_right_dual Y] [has_right_dual Z] {f : X ⟶ Y} {g : Y ⟶ Z} :
  (f ≫ g)^* = g^* ≫ f^* :=
begin
  rw right_adjoint_mate_comp,
  simp only [right_adjoint_mate, comp_tensor_id, iso.cancel_iso_inv_left, id_tensor_comp, category.assoc],
  symmetry, iterate 5 { transitivity, rw [←category.id_comp g, tensor_comp] },
  rw ←category.assoc,
  symmetry, iterate 2 { transitivity, rw ←category.assoc }, apply eq_whisker,
  repeat { rw ←id_tensor_comp }, congr' 1,
  rw [←id_tensor_comp_tensor_id (λ_ X^*).hom g, id_tensor_right_unitor_inv, category.assoc,
    category.assoc, right_unitor_inv_naturality_assoc, ←associator_naturality_assoc, tensor_id,
    tensor_id_comp_id_tensor_assoc, ←associator_naturality_assoc],
  slice_rhs 2 3 { rw [←tensor_comp, tensor_id, category.comp_id, ←category.id_comp (η_ Y Y^*), tensor_comp] },
  rw [←id_tensor_comp_tensor_id _ (η_ Y Y^*), ←tensor_id],
  repeat { rw category.assoc },
  rw [pentagon_hom_inv_assoc, ←associator_naturality_assoc, associator_inv_naturality_assoc],
  slice_rhs 5 7 { rw [←comp_tensor_id, ←comp_tensor_id, evaluation_coevaluation, comp_tensor_id] },
  rw associator_inv_naturality_assoc,
  slice_rhs 4 5 { rw [←tensor_comp, left_unitor_naturality, tensor_comp] },
  repeat { rw category.assoc },
  rw [triangle_assoc_comp_right_inv_assoc, ←left_unitor_tensor_assoc,
    left_unitor_naturality_assoc, unitors_equal, ←category.assoc, ←category.assoc], simp
end

@[reassoc]
lemma comp_left_adjoint_mate {X Y Z : C}
  [has_left_dual X] [has_left_dual Y] [has_left_dual Z] {f : X ⟶ Y} {g : Y ⟶ Z} :
  *^(f ≫ g) = *^g ≫ *^f :=
begin
  rw left_adjoint_mate_comp,
  simp only [left_adjoint_mate, id_tensor_comp, iso.cancel_iso_inv_left, comp_tensor_id, category.assoc],
  symmetry, iterate 5 { transitivity, rw [←category.id_comp g, tensor_comp] },
  rw ← category.assoc,
  symmetry, iterate 2 { transitivity, rw ←category.assoc }, apply eq_whisker,
  repeat { rw ←comp_tensor_id }, congr' 1,
  rw [←tensor_id_comp_id_tensor g (ρ_ *^X).hom, left_unitor_inv_tensor_id, category.assoc,
    category.assoc, left_unitor_inv_naturality_assoc, ←associator_inv_naturality_assoc, tensor_id,
    id_tensor_comp_tensor_id_assoc, ←associator_inv_naturality_assoc],
  slice_rhs 2 3 { rw [←tensor_comp, tensor_id, category.comp_id, ←category.id_comp (η_ *^Y Y), tensor_comp] },
  rw [←tensor_id_comp_id_tensor (η_ *^Y Y), ←tensor_id],
  repeat { rw category.assoc },
  rw [pentagon_inv_hom_assoc, ←associator_inv_naturality_assoc, associator_naturality_assoc],
  slice_rhs 5 7 { rw [←id_tensor_comp, ←id_tensor_comp, coevaluation_evaluation, id_tensor_comp ]},
  rw associator_naturality_assoc,
  slice_rhs 4 5 { rw [←tensor_comp, right_unitor_naturality, tensor_comp] },
  repeat { rw category.assoc },
  rw [triangle_assoc_comp_left_inv_assoc, ←right_unitor_tensor_assoc,
    right_unitor_naturality_assoc, ←unitors_equal, ←category.assoc, ←category.assoc], simp
end

lemma left_adjoint_of_right_adjoint {X Y : C} [has_right_dual X] [has_right_dual Y] (f : X ⟶ Y) :
  *^(f^*) = f :=
begin
  simp [left_adjoint_mate, right_adjoint_mate],
  rw [associator_naturality_assoc, associator_naturality_assoc,
    ←left_unitor_tensor', id_tensor_comp_assoc],
  slice_lhs 10 11 { rw [←tensor_comp, ←left_unitor_naturality, tensor_comp] },
  slice_lhs 8 9 { rw [←tensor_comp, associator_naturality, tensor_comp] },
  -- Slide the evaluations past each other
  slice_lhs 9 10 { rw [←tensor_comp, tensor_id, tensor_id_comp_id_tensor,
    ←id_tensor_comp_tensor_id (ε_ *^(X^*) X^*), tensor_comp] },
  rw pentagon_comp_id_tensor_assoc,
  slice_lhs 9 10 { rw ←associator_naturality },
  slice_lhs 5 6 { rw [←tensor_comp, ←tensor_comp, associator_inv_naturality, tensor_comp, tensor_comp] },
  slice_lhs 9 10 { rw associator_naturality },
  slice_lhs 8 9 { rw ←pentagon },
  simp only [inv_hom_id_tensor_assoc, tensor_id, category.id_comp, category.assoc],
  slice_lhs 6 7 { rw associator_naturality },
  slice_lhs 7 8 { rw [←tensor_comp, associator_naturality, tensor_comp] },
  -- Slide a evaluation past `f`
  slice_lhs 8 9 { rw [tensor_id, ←tensor_comp, tensor_id_comp_id_tensor,
    ←id_tensor_comp_tensor_id (ε_ *^(X^*) X^*), tensor_comp] },
  slice_lhs 5 6 { rw associator_naturality },
  slice_lhs 4 5 { rw associator_naturality },
  slice_lhs 5 5 { rw [←associator_conjugation, id_tensor_comp, id_tensor_comp] },
  slice_lhs 7 9 { rw [←tensor_comp, ←tensor_comp, pentagon_inv_inv_hom, tensor_comp, category.comp_id] },
  slice_lhs 8 9 { rw [←tensor_id, ←tensor_comp, ←associator_inv_naturality, tensor_comp] },
  -- Resolve evaluation and coevaluation for X
  slice_lhs 6 8 { erw [←tensor_comp, ←tensor_comp, ←tensor_comp, ←tensor_comp,
    evaluation_coevaluation *^(X^*) X^*, tensor_comp, tensor_comp, category.comp_id, category.comp_id] },
  simp only [category.assoc],
end

#exit
/- This theorem shows that right duals are isomorphic, which is almost trivial due to the
  previous theorem. -/
def right_dual_iso {X Y₁ Y₂ : C} (_ : exact_pairing X Y₁) (_ : exact_pairing X Y₂) :
  Y₁ ≅ Y₂ :=
{ hom := @right_adjoint_mate C _ _ X X ⟨Y₂⟩ ⟨Y₁⟩ (𝟙 X),
  inv := @right_adjoint_mate C _ _ X X ⟨Y₁⟩ ⟨Y₂⟩ (𝟙 X),
  hom_inv_id' := by rw [←comp_right_adjoint_mate, category.comp_id, right_adjoint_mate_id],
  inv_hom_id' := by rw [←comp_right_adjoint_mate, category.comp_id, right_adjoint_mate_id] }

def left_dual_iso {X₁ X₂ Y : C} (p₁ : exact_pairing X₁ Y) (p₂ : exact_pairing X₂ Y) :
  X₁ ≅ X₂ :=
{ hom := @left_adjoint_mate C _ _ Y Y ⟨X₂⟩ ⟨X₁⟩ (𝟙 Y),
  inv := @left_adjoint_mate C _ _ Y Y ⟨X₁⟩ ⟨X₂⟩ (𝟙 Y),
  hom_inv_id' := by rw [←comp_left_adjoint_mate, category.comp_id, left_adjoint_mate_id],
  inv_hom_id' := by rw [←comp_left_adjoint_mate, category.comp_id, left_adjoint_mate_id] }

@[simp]
lemma right_dual_iso_id {X Y : C} (p : exact_pairing X Y) :
  right_dual_iso p p = iso.refl Y :=
by { ext, simp only [right_dual_iso, iso.refl_hom, right_adjoint_mate_id] }

@[simp]
lemma left_dual_iso_id {X Y : C} (p : exact_pairing X Y) :
  left_dual_iso p p = iso.refl X :=
by { ext, simp only [left_dual_iso, iso.refl_hom, left_adjoint_mate_id] }

/- A right rigid monoidal category is one in which every object has a right dual. -/
class right_rigid_category (C : Type u) [category.{v} C] [monoidal_category.{v} C] :=
  [right_dual : Π (X : C), has_right_dual X]

class left_rigid_category (C : Type u) [category.{v} C] [monoidal_category.{v} C] :=
  [left_dual : Π (X : C), has_left_dual X]

attribute [instance] right_rigid_category.right_dual
attribute [instance] left_rigid_category.left_dual

class rigid_category (C : Type u) [category.{v} C] [monoidal_category.{v} C]
  extends right_rigid_category C, left_rigid_category C

end category_theory
