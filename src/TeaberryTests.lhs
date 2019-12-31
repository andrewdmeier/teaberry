
wrapper to lift tests written in the language into tests for the
 language implementation

> {-# LANGUAGE TupleSections #-}
> module TeaberryTests (sourceFiles
>                      ,testSourceFile
>                      ,detailedSourceFileTests
>                      ,testDetailedSourceFile) where

> import Data.List (partition)
> import Data.Maybe (isNothing)

> import qualified Test.Tasty as T
> import qualified Test.Tasty.HUnit as T

> import qualified Engine as E


> detailedSourceFileTests :: [(FilePath, Int, Int)]
> detailedSourceFileTests =
>     [(p "test_is_pass.tea", 1, 0)
>     ,(p "test_is_fail.tea", 0, 1)
>     ,(p "two_tests_pass.tea", 2, 0)
>     ,(p "two_tests_fail.tea", 0, 2)
>     ,(p "one_pass_one_fail.tea", 1, 1)
>      -- test trivial success for each kind of test
>      -- test trivial failure for each kind of test
>     ]
>   where
>       p = ("examples/tests/testing_tests/" ++)

> testDetailedSourceFile :: (FilePath, Int, Int) -> T.TestTree
> testDetailedSourceFile (fn, passNum, failNum) = T.testCase fn $ do
>     src <- readFile fn
>     cs <- E.runChecks src
>     let cnts = map passAndFailCount cs
>     T.assertEqual "pass, fail count"
>         (passNum,failNum)
>         (sum $ map fst cnts,sum $ map snd cnts)
>   where
>     passAndFailCount (E.CheckResult _cn ts) =
>         let (a,b) = partition (\(_,x) -> isNothing x) ts
>         in (length a, length b)

> -- these tests load the file, then run the tests from the files
> -- then hoist the tests into Tasty
> sourceFiles :: [FilePath]
> sourceFiles = map ("examples/tests/fulltests/" ++)
>     ["trivial_is.tea"]

> testSourceFile :: FilePath -> IO T.TestTree
> testSourceFile fp = do
>     src <- readFile fp
>     cs <- E.runChecks src
>     let ts :: [T.TestTree]
>         ts = map (getTests fp) cs
>     pure $ T.testGroup fp ts
>
> getTests :: FilePath -> E.CheckResult -> T.TestTree
> getTests fp (E.CheckResult cn ts) = T.testGroup (fp ++ " " ++ cn) $ do
>     flip map ts $ \(nm,msg) ->
>         T.testCase nm $ case msg of
>             Nothing -> T.assertBool "" True
>             Just fmsg -> T.assertFailure fmsg