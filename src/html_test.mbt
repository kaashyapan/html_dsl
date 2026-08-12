///|
test "login_snippet" {
  let expected =
    #|<html lang="en"><head><title>Sign in</title><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="stylesheet" href="/styles.css"></head><body><div class="min-h-screen flex items-center justify-center bg-gray-50"><div class="max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow"><h1>Sign in to your account</h1><form onsubmit="handleLogin(event)"><div class="space-y-4 my-4"><div class="flex gap-8"><label class="w-16" for="email">Email</label><input name="email" required type="email" placeholder="you@example.com"></div><div><label class="w-16" for="password">Password</label><input name="password" required type="password" placeholder="••••••••"></div></div><button class="w-full py-2 px-4 bg-blue-600 text-white rounded-lg" type="submit">Sign in</button></form><p class="text-center text-sm text-gray-500">Don&#39;t have an account? <a href="/register">Register</a></p></div></div></body></html>

  let snippet : Html = html_el(lang="en", [
    head([
      title("Sign in"),
      meta(charset="utf-8"),
      meta(attrs=[
        Name("viewport"),
        Prop("content", "width=device-width, initial-scale=1"),
      ]),
      link(rel="stylesheet", href="/styles.css"),
    ]),
    body([
      div(class="min-h-screen flex items-center justify-center bg-gray-50", [
        div(class="max-w-md w-full space-y-8 p-8 bg-white rounded-xl shadow", [
          h1([text("Sign in to your account")]),
          form(on_submit_="handleLogin(event)", [
            div(class="space-y-4 my-4", [
              div(class="flex gap-8", [
                label(class="w-16", for_="email", [text("Email")]),
                input(type_=Email, placeholder="you@example.com", attrs=[
                  Name("email"),
                  Required(true),
                ]),
              ]),
              div([
                label(class="w-16", for_="password", [text("Password")]),
                input(type_=Password, placeholder="••••••••", attrs=[
                  Name("password"),
                  Required(true),
                ]),
              ]),
            ]),
            button(
              type_=Submit,
              class="w-full py-2 px-4 bg-blue-600 text-white rounded-lg",
              [text("Sign in")],
            ),
          ]),
          p(class="text-center text-sm text-gray-500", [
            text("Don't have an account? "),
            a(href="/register", [text("Register")]),
          ]),
        ]),
      ]),
    ]),
  ])
  let actual = render(snippet)
  assert_eq(actual, expected)
}
