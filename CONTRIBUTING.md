# Contributing to Sum Zero

Thank you for your interest in contributing to Sum Zero! We welcome contributions that help improve the game, fix issues, and add new features. This guide will help you get started.

## Getting Started

1. **Fork the Repository**: Click the "Fork" button at the top-right of the repository page.
2. **Clone Your Fork**:
   ```sh
   git clone https://github.com/your-username/your-repository.git
   cd your-repository
   ```
3. **Create a Branch**: Always work on a separate branch from `main` or `develop`.
   ```sh
   git checkout -b feature/your-feature-name
   ```
4. **Install Godot**: Make sure you have **Godot 4.3** installed.
5. **Set Up Linter & Formatter**: We use [Godot GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) to maintain code quality.
   ```sh
   pip install gdtoolkit
   ```
6. **Run Linter & Formatter Before Committing**:
   ```sh
   gdlint your_script.gd
   gdformat your_script.gd
   ```

## Coding Guidelines

We follow the official **[Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)**. Please ensure your code adheres to it.

### Best Practices:
- Use **clear and descriptive names** for variables, functions, and classes.
- Follow **snake_case** for variables and functions, and **PascalCase** for classes.
- Keep functions **small and modular**.
- Avoid deep nesting; use **early returns** when possible.
- Add **docstrings** for public functions and classes.
- Use signals instead of tightly coupling scripts, following the "call down, signal up" principle:
  - Child nodes should never call methods on their parents, they should emit a signal.
  - Nodes can always call child function and, if possible, avoid emitting signals that will be listened from children.

## Git Workflow

We aim for a **clean and structured Git history**. Please follow these best practices:

1. **Use Conventional Commits**: Format your commit messages as specified in [Conventional Commits Guideline](https://www.conventionalcommits.org/en/v1.0.0/):
   ```
   type(scope): description
   ```

2. **Use Rebase Instead of Merge**:
   ```sh
   git fetch origin
   git rebase origin/main
   ```
3. **Squash Small Fixes** Before Pushing:
   ```sh
   git rebase -i HEAD~n
   ```
4. **Open a Pull Request (PR)**:
   - Describe the feature, issue, or bug fix.
   - Link any related issues (e.g., `Fixes #42`).
   - Request a review from a maintainer.

## Reporting Issues

If you find a bug or have an idea for an improvement:
1. **Check Existing Issues**: See if the issue has already been reported.
2. **Create a New Issue**:
   - Provide a clear title and description.
   - Include steps to reproduce if it’s a bug.
   - Suggest a possible solution if applicable.

## Additional Recommendations

- Use **scene inheritance** for reusing components.
- Prefer **resource files** (`.tres`, `.res`) for configuration instead of hardcoded values.
- Optimize assets (textures, audio) to reduce file size.
- Document complex systems using inline comments and README updates.
- While avoiding unnecessary repetition, we are **not strict DRY advocates**. It's often acceptable to **duplicate small pieces of code** if it makes the logic clearer and avoids unnecessary abstraction.

We appreciate your contributions and efforts in improving the project!
