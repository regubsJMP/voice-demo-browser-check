# mac browser probe

Checks how real Safari and Google Chrome on macOS behave for a web page that plays audio after a click, enters full screen from a
click, asks for the microphone and opens a file picker. Each GitHub Actions run gets a fresh macOS VM: the browsers are launched the
normal way (not through WebDriver, which grants the microphone silently), keys are pressed through System Events and the whole screen
is captured, so browser and system prompts are visible on the screenshots. Results: the `shots-safari` and `shots-chrome` artifacts.
