{-# LANGUAGE GADTs, TypeFamilies, MultiParamTypeClasses, FlexibleInstances, 
             FunctionalDependencies, FlexibleContexts #-}

module Exercises where

import Data.Kind (Type, Constraint)



{- ONE -}

-- | Let's introduce a new class, 'Countable', and some instances to match.
class Countable a where count :: a -> Int
instance Countable Int  where count   = id
instance Countable [a]  where count   = length
instance Countable Bool where count x = if x then 1 else 0

-- | a. Build a GADT, 'CountableList', that can hold a list of 'Countable'
-- things.

data CountableList where
  CNil :: CountableList
  CCons :: Countable a => a -> CountableList -> CountableList



-- | b. Write a function that takes the sum of all members of a 'CountableList'
-- once they have been 'count'ed.

countList :: CountableList -> Int
countList CNil = 0
countList (CCons x xs) = count x + countList xs


-- | c. Write a function that removes all elements whose count is 0.

dropZero :: CountableList -> CountableList
dropZero CNil = CNil
dropZero (CCons x xs) = (if count x == 0 then id else CCons x) (dropZero xs)


-- | d. Can we write a function that removes all the things in the list of type
-- 'Int'? If not, why not?

filterInts :: CountableList -> CountableList
filterInts = error "Contemplate me!"





{- TWO -}

-- | a. Write a list that can take /any/ type, without any constraints.

data AnyList where
  ANil :: AnyList
  ACons :: a -> AnyList -> AnyList

-- | b. How many of the following functions can we implement for an 'AnyList'?

reverseAnyList :: AnyList -> AnyList
reverseAnyList xs = run xs ANil
  where
    run ANil ys = ys
    run (ACons x xs) ys = run xs (ACons x ys)

filterAnyList :: (a -> Bool) -> AnyList -> AnyList
filterAnyList = undefined

lengthAnyList :: AnyList -> Int
lengthAnyList ANil = 0
lengthAnyList (ACons _ xs) = 1 + lengthAnyList xs

foldAnyList :: Monoid m => AnyList -> m
foldAnyList = undefined

isEmptyAnyList :: AnyList -> Bool
isEmptyAnyList ANil = True
isEmptyAnyList _ = False

instance Show AnyList where
  show = error "What about me?"





{- THREE -}

-- | Consider the following GADT:

data TransformableTo output where
  TransformWith
    :: (input -> output)
    ->  input
    -> TransformableTo output

-- | ... and the following values of this GADT:

transformable1 :: TransformableTo String
transformable1 = TransformWith show 2.5

transformable2 :: TransformableTo String
transformable2 = TransformWith (uncurry (++)) ("Hello,", " world!")

-- | a. Which type variable is existential inside 'TransformableTo'? What is
-- the only thing we can do to it?

-- | b. Could we write an 'Eq' instance for 'TransformableTo'? What would we be
-- able to check?

instance Eq a => Eq (TransformableTo a) where
  TransformWith fx x == TransformWith fy y = fx x == fy y

-- | c. Could we write a 'Functor' instance for 'TransformableTo'? If so, write
-- it. If not, why not?

instance Functor TransformableTo where
  fmap f (TransformWith g x) = TransformWith (fmap f g) x



{- FOUR -}

-- | Here's another GADT:

data EqPair where
  EqPair :: Eq a => a -> a -> EqPair

-- | a. There's one (maybe two) useful function to write for 'EqPair'; what is
-- it?

eqPair :: EqPair -> Bool
eqPair (EqPair x y) = x == y

-- | b. How could we change the type so that @a@ is not existential? (Don't
-- overthink it!)

data EqPair' a where
  EqPair' :: Eq a => a -> a -> EqPair' a

-- | c. If we made the change that was suggested in (b), would we still need a
-- GADT? Or could we now represent our type as an ADT?

data EqPair'' a = Eq a => EqPair'' a a

{- FIVE -}

-- | Perhaps a slightly less intuitive feature of GADTs is that we can set our
-- type parameters (in this case @a@) to different types depending on the
-- constructor.

data MysteryBox a where
  EmptyBox  ::                                MysteryBox ()
  IntBox    :: Int    -> MysteryBox ()     -> MysteryBox Int
  StringBox :: String -> MysteryBox Int    -> MysteryBox String
  BoolBox   :: Bool   -> MysteryBox String -> MysteryBox Bool

-- | When we pattern-match, the type-checker is clever enough to
-- restrict the branches we have to check to the ones that could produce
-- something of the given type.

getInt :: MysteryBox Int -> Int
getInt (IntBox int _) = int

-- | a. Implement the following function by returning a value directly from a
-- pattern-match:

getInt' :: MysteryBox String -> Int
getInt' (StringBox _ (IntBox int _)) = int

-- | b. Write the following function. Again, don't overthink it!

countLayers :: MysteryBox a -> Int
countLayers EmptyBox = 0
countLayers (IntBox _ xs) = 1 + countLayers xs
countLayers (StringBox _ xs) = 1 + countLayers xs
countLayers (BoolBox _ xs) = 1 + countLayers xs

-- | c. Try to implement a function that removes one layer of "Box". For
-- example, this should turn a BoolBox into a StringBox, and so on. What gets
-- in our way? What would its type be?

type family Convert (a :: Type) :: Type where
  Convert Int = ()
  Convert String = Int
  Convert Bool = String

peel' :: Convert a ~ b => MysteryBox a -> MysteryBox b
peel' (IntBox _ xs) = xs
peel' (StringBox _ xs) = xs
peel' (BoolBox _ xs) = xs

class Peel (a :: Type) (b :: Type) | a -> b where
  peel :: MysteryBox a -> MysteryBox b

instance Peel Int () where
  peel (IntBox _ xs) = xs

instance Peel String Int where
  peel (StringBox _ xs) = xs

instance Peel Bool String where
  peel (BoolBox _ xs) = xs

{- SIX -}

-- | We can even use our type parameters to keep track of the types inside an
-- 'HList'!  For example, this heterogeneous list contains no existentials:

data HList a where
  HNil  :: HList ()
  HCons :: head -> HList tail -> HList (head, tail)

exampleHList :: HList (String, (Int, (Bool, ())))
exampleHList = HCons "Tom" (HCons 25 (HCons True HNil))

-- | a. Write a 'head' function for this 'HList' type. This head function
-- should be /safe/: you can use the type signature to tell GHC that you won't
-- need to pattern-match on HNil, and therefore the return type shouldn't be
-- wrapped in a 'Maybe'!

head :: HList (head, tail) -> head
head (HCons x _) = x

-- | b. Currently, the tuples are nested. Can you pattern-match on something of
-- type @HList (Int, String, Bool, ())@? Which constructor would work?

patternMatchMe :: HList (Int, String, Bool, ()) -> Int
patternMatchMe = undefined

-- | c. Can you write a function that appends one 'HList' to the end of
-- another? What problems do you run into?





{- SEVEN -}

-- | Here are two data types that may help:

data Empty
data Branch left centre right

-- | a. Using these, and the outline for 'HList' above, build a heterogeneous
-- /tree/. None of the variables should be existential.

data HTree a where
  HLeaf :: HTree Empty
  HNode :: HTree l -> c -> HTree r -> HTree (Branch l c r)

-- | b. Implement a function that deletes the left subtree. The type should be
-- strong enough that GHC will do most of the work for you. Once you have it,
-- try breaking the implementation - does it type-check? If not, why not?

deleteLeft :: HTree (Branch l c r) -> HTree (Branch Empty c r)
deleteLeft (HNode l c r) = HNode HLeaf c r

-- | c. Implement 'Eq' for 'HTree's. Note that you might have to write more
-- than one to cover all possible HTrees. You might also need an extension or
-- two, so look out for something... flexible... in the error messages!
-- Recursion is your friend here - you shouldn't need to add a constraint to
-- the GADT!

instance Eq (HTree Empty) where
  HLeaf == HLeaf = True

instance (Eq (HTree l), Eq c, Eq (HTree r)) => Eq (HTree (Branch l c r)) where
  HNode l1 c1 r1 == HNode l2 c2 r2 = l1 == l2 && c1 == c2 && r1 == r2


{- EIGHT -}

-- | a. Implement the following GADT such that values of this type are lists of
-- values alternating between the two types. For example:
--
-- @
--   f :: AlternatingList Bool Int
--   f = ACons True (ACons 1 (ACons False (ACons 2 ANil)))
-- @

data AlternatingList a b where
  ALNil :: AlternatingList a b
  ALCons :: a -> AlternatingList b a -> AlternatingList a b

-- | b. Implement the following functions.

getFirsts :: AlternatingList a b -> [a]
getFirsts ALNil = []
getFirsts (ALCons x xs) = x : getSeconds xs

getSeconds :: AlternatingList a b -> [b]
getSeconds ALNil = []
getSeconds (ALCons x xs) = getFirsts xs

-- | c. One more for luck: write this one using the above two functions, and
-- then write it such that it only does a single pass over the list.

foldValues :: (Monoid a, Monoid b) => AlternatingList a b -> (a, b)
foldValues x = (mconcat $ getFirsts x, mconcat $ getSeconds x)

foldValues' :: (Monoid a, Monoid b) => AlternatingList a b -> (a, b)
foldValues' ALNil = (mempty, mempty)
foldValues' (ALCons x xs) = (mappend x a, b)
  where
    (b, a) = foldValues' xs

{- NINE -}

-- | Here's the "classic" example of a GADT, in which we build a simple
-- expression language. Note that we use the type parameter to make sure that
-- our expression is well-formed.

data Expr a where
  Equals    :: Expr Int  -> Expr Int            -> Expr Bool
  Add       :: Expr Int  -> Expr Int            -> Expr Int
  If        :: Expr Bool -> Expr a   -> Expr a  -> Expr a
  IntValue  :: Int                              -> Expr Int
  BoolValue :: Bool                             -> Expr Bool

-- | a. Implement the following function and marvel at the typechecker:

eval :: Expr a -> a
eval (Equals x y) = eval x == eval y
eval (Add x y) = eval x + eval y
eval (If x y z) = if eval x then eval y else eval z
eval (IntValue x) = x
eval (BoolValue x) = x

-- | b. Here's an "untyped" expression language. Implement a parser from this
-- into our well-typed language. Note that (until we cover higher-rank
-- polymorphism) we have to fix the return type. Why do you think this is?

data DirtyExpr
  = DirtyEquals    DirtyExpr DirtyExpr
  | DirtyAdd       DirtyExpr DirtyExpr
  | DirtyIf        DirtyExpr DirtyExpr DirtyExpr
  | DirtyIntValue  Int
  | DirtyBoolValue Bool

parse :: DirtyExpr -> Maybe (Expr Int)
parse (DirtyEquals _ _) = Nothing
parse (DirtyBoolValue _) = Nothing
parse (DirtyIntValue x) = Just (IntValue x)
parse (DirtyAdd x y) = Add <$> parse x <*> parse y
parse (DirtyIf x y z) = If <$> parseBool x <*> parse y <*> parse z

parseBool :: DirtyExpr -> Maybe (Expr Bool)
parseBool (DirtyEquals x y) = Equals <$> parse x <*> parse y
parseBool (DirtyBoolValue x) = pure (BoolValue x)
parseBool (DirtyIntValue _) = Nothing
parseBool (DirtyAdd _ _) = Nothing
parseBool (DirtyIf x y z) = If <$> parseBool x <*> parseBool y <*> parseBool z

-- | c. Can we add functions to our 'Expr' language? If not, why not? What
-- other constructs would we need to add? Could we still avoid 'Maybe' in the
-- 'eval' function?



{- TEN -}

-- | Back in the glory days when I wrote JavaScript, I could make a composition
-- list like @pipe([f, g, h, i, j])@, and it would pass a value from the left
-- side of the list to the right. In Haskell, I can't do that, because the
-- functions all have to have the same type :(

-- | a. Fix that for me - write a list that allows me to hold any functions as
-- long as the input of one lines up with the output of the next.

data TypeAlignedList a b where
  TANil :: TypeAlignedList a a
  TACons :: (a -> b) -> TypeAlignedList b c -> TypeAlignedList a c

-- | b. Which types are existential?

-- | c. Write a function to append type-aligned lists. This is almost certainly
-- not as difficult as you'd initially think.

composeTALs :: TypeAlignedList b c -> TypeAlignedList a b -> TypeAlignedList a c
composeTALs ys TANil = ys
composeTALs ys (TACons x xs) = TACons x (composeTALs ys xs)
