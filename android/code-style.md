# Android Style Guide

It is based on [Kotlin's coding conventions](https://kotlinlang.org/docs/reference/coding-conventions.html)

It was inspired by [GitHub's Ruby guide](https://web.archive.org/web/20160410033955/https://github.com/styleguide/ruby) and [Airbnb's Ruby guide](https://github.com/airbnb/ruby).

## Table of Contents
  * [Source code organization](#source-code-organization)
  * [Id naming](#id-naming)
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

## Id naming

In a CustomView / Layout we don't need to specify the name of the (class / customview) in our id

For example, for the class `CalendarStartingMonthChoiceView` :

dont use -> tv_calendar_starting_month_choice_title

just use -> tv_title

### XML

TextView -> tv_something (example : tv_title / tv_message / tv_description)

ImageView -> iv_something (example : iv_icon / iv_header / iv_background)

EditText -> et_something (example : et_firstName / et_city / et_address)

MaterialButton -> btn_something (example : btn_back / btn_next / btn_login)


For custom view / Layout, dont prefix by `view_` or `layout_`, be consistent 

example -> for BillingShippingAddressView, for the id, we can put something like 

`android:id="@+id/shipping_address_container"` or `android:id="@+id/container_shipping_address"`

Sometime, you will have TextView or ImageView for a button. In this case, your id should be : 

`android:id="@+id/btn_something"` and not `android:id="@+id/tv_something"` / `android:id="@+id/iv_something"`

### Class / Layout / Custom View

TextView -> tvSomething (example : tvTitle / tvMessage / tvDescription)

ImageView -> ivSomething (example : ivIcon / ivHeader / ivBackground)

EditText -> etSomething (example : etFirstName / etCity / etAddress)

MaterialButton -> btnSomething (example : btnBack / btnNext / btnLogin)


For customView / Layout, we also dont need to prefix by `view`Something (example : viewBillingShippingAddress)
we can write something like : `private val selectionTopBar: Selection3TopBarView`

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

### Getting RecyclerView's adapter

Two ways of getting a RecyclerView's adapter can be found.

```kotlin
// 1st kind : storing the adapter
class MyFragment : Fragment() {
    private val recyclerView: RecyclerView
    private lateinit var adapter: MyAdapter

    override fun onCreate() {
        adapter = MyAdapter()
        recyclerView.adapter = newAdapter
    }

    private fun doStuffOnAdapter() {
        // The adapter can be got directly from the field of this fragment
    }
}

// 2nd kind : getting the adapter in the RecyclerView
class MyFragment : Fragment() {
    private val recyclerView: RecyclerView

    override fun onCreate() {
        recyclerView.adapter = MyAdapter()
    }

    private fun getAdapter() = recyclerView.adapter as MyAdapter

    private fun doStuffOnAdapter() {
        // The adapter can be got from the getAdapter() method
    }
}
```

Either the first and second type of getting the adapter is accepted in the project. In the first case, be careful that the stored adapter is always the one set in the RecyclerView. In the second case, keep in mind that it requires more computational work.
<sup>[[link](#Getting-RecyclerViews-adapter)]</sup>

### Event spreading

#### Managed implementation

In the case of a managed parent/child implementation, the emitter can expose a method to pass either a callback or a lamba depending of the complexity of information to spread.
The Emitter can accept one or many listeners.

 ```kotlin
 // Set a single lambda
 fun setOnEventListener(lambda: (SomeData) -> Unit)

// Add a new callback
 fun addOnEventListener(callback: Callback)
 ```
<sup>[[link](#managed-implementation)]</sup>

#### Unmanaged implementation

When creating reusable components, you are not necessarily aware of how many layers will separate the emitter from the receiver.
In this case, creating a publish/subscribe pattern could help implementation and maintainability.

[Illustration of a problem with the different solutions that can be used](https://docs.google.com/drawings/d/1QPfs1hEdWlpZ_SfFAuUKA6tJanA-8RtDMiASfBY8yPo/edit?usp=sharing). Here we choose the solution 2.

Implementation example :
```kotlin
class GalleryActivity : AppCompatActivity() {

    private val photoViewCallbacks: PhotoView.Callback = object : PhotoView.Callback() {
        override fun onClick(photoData: SomePhotoData) {
            super.onClick(photoData)
            // handle simple click here
        }

        // onLongClick does not need to be implemented
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ...
        PhotoView.Events.subscribe(photoViewCallbacks)
    }

    override fun onDestroy() {
        PhotoView.Events.unsubscribe(photoViewCallbacks)
        ...
        super.onDestroy()
    }
}

class PhotoView : View {
    private val currentPhoto = SomePhotoData()

    init {
        setOnClickListener { Events.emitOnClick(currentPhoto) }
        setOnLongClickListener { Events.emitOnLongClick(currentPhoto); true }
    }

    abstract class Callback {
        open fun onClick(photoData: SomePhotoData) {}
        open fun onLongClick(photoData: SomePhotoData) {}
    }

    object Events {
        private val listeners: Set = HashSet<Callback>()

        fun subscribe(callback: Callback): Boolean = listeners.add(callback)

        fun unsubscribe(callback: Callback): Boolean = listeners.remove(callback)

        fun emitOnClick(photoData: SomePhotoData) {
            listeners.forEach {
                try {
                    it.onClick(photoData)
                } catch (e: Exception) {
                    // handle exception to prevent to allow all listeners to be called.
                }
            }
        }

        fun emitOnLongClick(photoData: SomePhotoData) {
            listeners.forEach {
                try {
                    it.onLongClick(photoData)
                } catch (e: Exception) {
                    // handle exception to prevent to allow all listeners to be called.
                }
            }
        }
    }
}
```
Note 1: When storing a list of callbacks/listeners always use `Set` to avoid duplication issues.

Note 2: The encapsulation of `Events` and `Callback` inside `PhotoView` is not mandatory.
If `PhotoView.Events` and `PhotoView.Callback` grow too much, it's perfectly fine to create external classes: `PhotoViewEvents` and `PhotoViewCallback`.
<sup>[[link](#unmanaged-implementation)]</sup>

### View visibility management
We have multiple ways to change a view visibility.
We can use the original `View.setVisibility(visibility: Int)` with `visibility` as an integer value between `View.VISIBLE`, `View.INVISIBLE` or `View.GONE` ; or with AndroidX core KTX use inline vars `View.isVisible: Boolean`, `View.isInvisible: Boolean` and `View.isGone: Boolean`.
By default we recommend to use `View.isVisible: Boolean` instead of `View.setVisibility(visibility: Int)` with `View.VISIBLE` or `View.GONE`. Thus, to set a view as `GONE` (not visible), we should use `isVisible` setting the property to `false `(not use `View.isGone: Boolean`)

As setting a view as invisible is less common and often related between switching view from invisible to visible, we continue to use `View.setVisibility(visibility: Int)` with `View.INVISIBLE`.

```kotlin
    // Bad using setVisibility only
    private fun manageCompanyInfoShowing(isComplementAddressShowing: Boolean) {
        if (isComplementAddressShowing) {
            tvAddCompanyInfo.setVisibility(View.GONE)
            inputLayoutCompany.setVisibility(View.VISIBLE)
            inputLayoutVat.setVisibility(View.VISIBLE)
        } else {
            tvAddCompanyInfo.setVisibility(View.VISIBLE)
            inputLayoutCompany.setVisibility(View.GONE)
            inputLayoutVat.setVisibility(View.INVISIBLE)
        }
    }
```

```kotlin
    // Good and concise with KTX for visible and gone visibility state
    private fun manageCompanyInfoShowing(isComplementAddressShowing: Boolean) {
        tvAddCompanyInfo.isVisible = !isComplementAddressShowing
        inputLayoutCompany.isVisible = isComplementAddressShowing
        val vatVisibility = if (isComplementAddressShowing) View.VISIBLE else View.INVISIBLE
        inputLayoutVat.setVisibility(vatVisibility)
    }
```

As we can see, using KTX view visibility can be more concise and more readable.

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
