# Android Style Guide

It is based on [Kotlin's coding conventions](https://kotlinlang.org/docs/reference/coding-conventions.html)

It was inspired by [GitHub's Ruby guide](https://web.archive.org/web/20160410033955/https://github.com/styleguide/ruby) and [Airbnb's Ruby guide](https://github.com/airbnb/ruby).

## Table of Contents
  * [Source code organization](#source-code-organization)
  * [Naming rules](#naming-rules)
  * [Formatting](#formatting)
  * [Code idioms](#code-idioms)
  * [Framework specificities](#framework-specificities)

## Source code organization

### Class layout

Generally, the contents of a class is sorted in the following order:

* Property declarations and initializer blocks
* Secondary constructors
* Method declarations
* Companion object
* Nested classes

For Android/framework classes (e.g. `Activity` or `Fragment`) put framework methods first.
Also, put related stuff together, so that someone reading the class from top to bottom would be able to follow the logic of what's happening.
Higher-level stuff should go first (after framework methods if there are any).
<sup>[[link](#class-layout)]</sup>

### Interface implementation layout

When implementing an interface, keep the implementing members in the same order as members of the interface.
<sup>[[link](#interface-implementation-layout)]</sup>

### Overload layout

Always put overloads next to each other in a class.
<sup>[[link](#overload-layout)]</sup>

## Naming rules

### Naming modules

Names of modules are **always lower case** (`app`).
Using multi-word names is generally discouraged, but if you do need to use multiple words, use **snake case** (`selection-store`).

Names of modules should not be prefixed using company name (e.g. `cz-app`).
<sup>[[link](#naming-modules)]</sup>

### Naming packages

Names of packages are **always lower case** and do NOT use underscores (`com.example.network`).
Using multi-word names is generally discouraged, but if you do need to use multiple words, you can simply concatenate them together (`com.example.mypackage`).
<sup>[[link](#naming-packages)]</sup>

### Naming test methods

In tests (and only in tests), it's acceptable to use method names with spaces enclosed in backticks. Underscores in method names are also allowed in test code.
<sup>[[link](#naming-test-methods)]</sup>

```kotlin
class MyTestCase {
     @Test fun `ensure everything works`() { ... }
     
     @Test fun ensureEverythingWorks_onAndroid() { ... }
}
```
### Add names to call argument methods

When using method with argument that are not named in a property (null, or magic string or magic number) it is recommended to add the names to the argument methods. It adds context and allow code review to be easier than without them.
```kotlin
val draft = DraftItem(
    existingDraftMetadata.id,
    null,                // bad
    "",                  // bad
    dateOfCreation
)
```
```kotlin
val draft = DraftItem(
    existingDraftMetadata.id,
    imageUrl = null,     // good
    title = "",          // good
    dateOfCreation
)
```

### Choosing good names

**Names should be meaningful and concise.**

The names should make it clear what the purpose of the entity is, so it's best to avoid using generic words (`Manager`, `Wrapper`, etc.) as names.

The name of a class is usually a noun or a noun phrase explaining what the class _is_: `List`, `PersonReader`.

The name of a method is usually a verb or a verb phrase saying what the method _does_: `close`, `readPersons`.
The name should also suggest if the method is mutating the object or returning a new one. For instance `sort` is sorting a collection in place, while `sorted` is returning a sorted copy of the collection.
<sup>[[link](#choosing-good-names)]</sup>

<a name="naming-acronyms"></a>
When using an acronym as part of a declaration name, capitalize it if it consists of two letters (`IOStream`); capitalize only the first letter if it is longer (`XmlFormatter`, `HttpInputStream`).
<sup>[[link](#choosing-good-names)]</sup>

### Naming constants

#### Activities (or Fragment) arguments

Activity (namely Fragment) arguments names should be **prefixed** by `ARG_`
Example : `ARG_PRODUCT_TAG`

Implementation examples :
**Activity**
```kotlin
class MyActivity : AppCompatActivity() {
    ...

    companion object {
        private const val ARG_MIN_PHOTO_COUNT = "min_photo_count"
        private const val ARG_SELECTION_ID = "selection_id"
        private const val ARG_SELECTION_MODE = "selection_mode"
        private const val ARG_PRODUCT_TAG = "product_tag"

        fun startIntent(
            context: Context,
            model: Kustomization.Model,
            selectionId: String,
            selectionMode: GallerySelectionMode
        ) = Intent(context, MyActivity::class.java)
            .apply {
                putExtra(ARG_MIN_PHOTO_COUNT, selectionId)
                putExtra(ARG_SELECTION_ID, model.minPagesCount)
                putExtra(ARG_SELECTION_MODE, model.productTag)
                putExtra(ARG_PRODUCT_TAG, selectionMode)
            }
    }
}
```

**Fragment**
```kotlin
class MyFragment : Fragment() {
    ...

    companion object {
        private const val ARG_MIN_PHOTO_COUNT = "min_photo_count"
        private const val ARG_SELECTION_ID = "selection_id"

        fun newInstance(minCountPhoto: Int, selectionId: String) = MyFragment()
            .apply { 
                arguments = bundleOf(
                    ARG_MIN_PHOTO_COUNT to minCountPhoto,
                    ARG_SELECTION_ID to selectionId
                )
            }
    }
}
```

#### Keys of key/value pairs

Given a set of keys and values, we may want to have constants defined for the keys. The constants must be **prefixed** by `KEY_`. This prefix does not apply in the special case of arguments of fragments or activities.
Example : `KEY_PRODUCT_TAG`

Implementation example :
```kotlin
const val KEY_PRODUCT_TAG_MAGNET = "product_tag_magnet"
const val KEY_PRODUCT_TAG_DIBOND = "product_tag_dibond"

val productTags = mapOf<String, String>(
    KEY_PRODUCT_TAG_MAGNET to "magnet-retro"
    KEY_PRODUCT_TAG_DIBOND to "metallic-print"
)

val dibondTag = productTags[KEY_PRODUCT_TAG_DIBOND]
```

#### Prefix and grouping keys

It's a good practice to regroup and prefix keys that are related to each other.

```kotlin
const val KEY_PRODUCT_TAG_MAGNET = "product_tag_magnet"
const val KEY_PRODUCT_TAG_DIBOND = "product_tag_dibond"

const val KEY_ACTION_ADD = "action_delete"
const val KEY_ACTION_DELETE = "action_add"
```

### Naming images resources

#### Icons
Icons defined in the design system must be set in the design module. 
They must be prefixed by `ic_` and suffixed by their size (24 or 16 dp).

It means for example that `ic_activity_24` is for the icon named activity and with size 24x24.

Icons are mono color, so they can be easily tinted when used.

#### Design System images (AKA icons bicolors)
These images which are vectors with multiple colors are also located in the design module if they are defined in the design system.
The are prefixed by `img_` and suffixed by their size (meaning 160, 72 or 24 dp). 

For instance `img_package_72`is for the image named package and with size 72x72.

When importing the vector asset, remove hardcoded colors in the XML describing the icons and set the associated color (@color/foo). 

As these images are not mono color, it's not possible to tint them at use. 
Don't forget to import both the normal and the dark mode version of an image.

## Formatting

### Indentation

Use 4 spaces for indentation. Do not use tabs.
<sup>[[link](#indentation)]</sup>

### Line Length

Keep each line of code to a readable length. Unless you have a reason to, keep lines to fewer than `120` characters.
<sup>[[link](#line-length)]</sup>

### Horizontal whitespace

Put spaces around binary operators (`a + b`). Exception: don't put spaces around the "range to" operator (`0..i`).

Do not put spaces around unary operators (`a++`)

Put spaces between control flow keywords (`if`, `when`, `for` and `while`) and the corresponding opening parenthesis.

Do not put a space before an opening parenthesis in a primary constructor declaration, method declaration or method call.

```kotlin
class A(val x: Int)

fun foo(x: Int) { ... }

fun bar() {
    foo(1)
}
```

Never put a space after `(`, `[`, or before `]`, `)`.

Never put a space around `.` or `?.`: `foo.bar().filter { it > 2 }.joinToString()`, `foo?.bar()`

Put a space after `//`: `// This is a comment`

Do not put spaces around angle brackets used to specify type parameters: `class Map<K, V> { ... }`

Do not put spaces around `::`: `Foo::class`, `String::length`

Do not put a space before `?` used to mark a nullable type: `String?`

As a general rule, avoid horizontal alignment of any kind. Renaming an identifier to a name with a different length should not affect the formatting of either the declaration or any of the usages.

### Function and expression body formatting

<a name="formating-single-line-expression"></a>
Prefer using an expression body for functions with the body consisting of a single expression.
<sup>[[link](#formating-single-line-expression)]</sup>

```kotlin
fun foo(): Int { // bad
    return 1
}
```
```kotlin
fun foo() = 1    // good
```

<a name="formating-multiline-expression-body"></a>
If the function has an expression body that doesn't fit in the same line as the declaration, put the `=` sign on the first line. Indent the expression body by 4 spaces.
<sup>[[link](#formating-multiline-expression-body)]</sup>

```kotlin
fun f(x: String) =
    x.length
```

### Formatting control flow statements

<a name="formating-multiline-condition-statement"></a>
If the condition of an `if` or `when` statement is multiline, always use curly braces around the body of the statement. Put the closing parentheses of the condition together with the opening curly brace on a separate line:
<sup>[[link](#formating-multiline-condition-statement)]</sup>

```kotlin
if (!component.isSyncing &&
    !hasAnyKotlinRuntimeInScope(module)
) {
    return createKotlinNotConfiguredPanel(module)
}
```

<a name="formating-affirmative-condition-statement"></a>
Prefer affirmative statements to negative ones.
<sup>[[link](#formating-affirmative-condition-statement)]</sup>

```kotlin
if (!statment) {  // Bad
    doIfFalse()
} else {
    doIfTrue()
}
```
```kotlin
if (statment) {   // Good
    doIfTrue()
} else {
    doIfFalse()
}
```

<a name="formating-curly-brace"></a>
Put the `else`, `catch`, `finally` keywords, as well as the `while` keyword of a do/while loop, on the same line as the preceding curly brace:
<sup>[[link](#formating-curly-brace)]</sup>

```kotlin
if (condition) {
    // body
} else {
    // else part
}

try {
    // body
} finally {
    // cleanup
}
```

### Chained call wrapping

When wrapping chained calls, put the `.` character or the `?.` operator on the next line, with a single indent:

```kotlin
val anchor = owner
    ?.firstChild
    .siblings(forward = true)
    .dropWhile { it is PsiComment || it is PsiWhiteSpace }
```

The first call in the chain usually should have a line break before it, but it's OK to omit it if the code makes more sense that way.
<sup>[[link](#chained-call-wrapping)]</sup>

### New lines

<a name="new-line-after-conditional"></a>
Add a new line after conditionals, blocks, case statements, etc.
<sup>[[link](#new-line-after-conditional)]</sup>

```kotlin
if (robot.isAwesome) {
    doSomething()
}

doSomehtingElse()
```

<a name="newline-between-methods"></a>
Include one, but no more than one, new line between methods.
<sup>[[link](#newline-between-methods)]</sup>

```kotlin
// Bad
fun doSomething() { ... }


fun doSomethingElse() { ... }
```
```kotlin
// Good
fun doSomething() { ... }

fun doSomethingElse() { ... }
```

### Trailing commas

<a name="trailing-commas"></a>
Add a tailing comma `,` after function, constructor, lambda parameters, when there is more than 1 parameter. 
It allows to simplify the diff when adding new parameters to them.
<sup>[[link](#trailing-commas)]</sup>

```kotlin
// Bad
class NoCommas(
  val foo: Int,
  val bar: Int
)

// Good
class YesCommas(
  val foo: Int,
  val bar: Int,
)

// Good 
class OneLineNoComma(val foo: Int)
```

## Code idioms

### Early return

Prefer early return syntax over big `if`/`else` blocks.

* Nesting code is reduced which makes the functions easier to read.
* `if`/`else` statements will be closer together and you’ll be doing less hunting for opening and closing brackets.
* The function reads more linear. Human brains are better at parsing linear things.
* Often, you won't have to read the whole method to understand its behavior.
<sup>[[link](#early-return)]</sup>

```kotlin
// Bad
fun doSomething(condition: Boolean) {

    if (condition) {
    
        // A
        // lot 
        // of 
        // code 
        // here

    } else {
        throw Exception(...)
    }
}
```

```kotlin
// Good
fun doSomething(condition: Boolean) {

    if (!condition) {
       throw Exception(...)
    }
    
    // A
    // lot 
    // of 
    // code 
    // here
}
```

```kotlin
// Bad
fun doSomething(someCondition: Boolean, name: String?, intValue: Int): String {

    var result = "SUCCESS"

    if (someCondition) {
        if (!name.isNullOrBlank()) {
            if (intValue != 0) {
                // Do Something here
            } else {
                result = "BAD_VALUE"
            }
        } else {
            result = "BAD_NAME"
        }
    } else {
        result = "BAD_CONDITION"
    }

    return result
}
```

```kotlin
// Good
fun doSomething(someCondition: Boolean, name: String?, intValue: Int): String {

    if (!someCondition) {
        return "BAD_CONDITION"
    }

    if (name.isNullOrBlank()) {
        return "BAD_NAME"
    }

    if (intValue == 0) {
        return "BAD_VALUE"
    }

    // Do Something
    
    return "SUCCESS"
}
```

Note: As shown in the previous examples, skipping a line after a return statement improves readability.
<sup>[[link](#early-return)]</sup>

## Framework specificities

### List state in Compose

Use `LazyColumn` / `LazyRow` for lists. When the parent needs to control or observe scroll position, hoist a `LazyListState` rather than reaching into child composables.

```kotlin
// Good: state is hoisted, the caller controls it
val listState = rememberLazyListState()

LazyColumn(state = listState) {
    items(items) { item -> ItemRow(item) }
}

// Elsewhere: scroll to top on refresh
LaunchedEffect(refreshTrigger) {
    listState.animateScrollToItem(0)
}
```

When the caller doesn't need to interact with scroll state, let `LazyColumn` own it internally — don't hoist unnecessarily.
<sup>[[link](#list-state-in-compose)]</sup>

### Event propagation

Use `ViewModel` as the single source of truth. Expose **state** via `StateFlow` and **one-shot events** via `SharedFlow` (or `Channel`). Composables collect these flows and react accordingly — no manual subscribe/unsubscribe, no custom callback interfaces.

```kotlin
// ViewModel
class GalleryViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(GalleryUiState())
    val uiState: StateFlow<GalleryUiState> = _uiState.asStateFlow()

    private val _events = MutableSharedFlow<GalleryEvent>()
    val events: SharedFlow<GalleryEvent> = _events.asSharedFlow()

    fun onPhotoClick(photo: Photo) {
        viewModelScope.launch { _events.emit(GalleryEvent.OpenPhoto(photo)) }
    }
}

// Composable
@Composable
fun GalleryScreen(viewModel: GalleryViewModel = viewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is GalleryEvent.OpenPhoto -> { /* navigate */ }
            }
        }
    }
}
```

Prefer `StateFlow` for state that must survive recomposition; prefer `SharedFlow` (replay = 0) for fire-and-forget events such as navigation or snackbars.
<sup>[[link](#event-propagation)]</sup>

### Visibility in Compose

In Compose, showing or hiding content is expressed with a plain `if`. There is no equivalent of `INVISIBLE` (occupying space while hidden) — use `Spacer` with a fixed size if a placeholder is needed.

```kotlin
// Good: content simply doesn't exist when hidden
if (isCompanyInfoVisible) {
    CompanyInfoSection()
}

// Good: animated transition
AnimatedVisibility(visible = isCompanyInfoVisible) {
    CompanyInfoSection()
}
```

Prefer `AnimatedVisibility` when the appearance/disappearance benefits from a transition; use a bare `if` otherwise.
<sup>[[link](#visibility-in-compose)]</sup>

### Content description
For illustration, icons etc. we decided that instead of setting empty content description we should use null
```kotlin
// Good usage of image without content description
LoadableImage(
    url = url,
    contentDescription = null,
)
```
```kotlin
// Bad usage of image without content description
LoadableImage(
    url = url,
    contentDescription = "",
)
```        
