// Nix とネットワークを使わず、一時ホームで Linux の配置処理を検証する。
// 実行: dotnet run tests/LinuxSetup.cs [-- -method "*Wsl*"]
#:package xunit.v3@4.0.2
#:property NoWarn=CA1416
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Text.Json;
using Xunit;

public sealed class LinuxSetupTests : IDisposable
{
  readonly TestHome t = new();
  public void Dispose() => t.Dispose();

  [Fact]
  public void DotfilesAreIdempotentAndToolsAreGlobal()
  {
    t.Mise("dotfiles", "apply", "--yes");
    t.Mise("dotfiles", "apply", "--yes");
    t.Mise("dotfiles", "status", "--missing");
    AssertLinksTo(t.At(".bashrc"), Path.Combine(TestHome.Root, "dotfiles/.bashrc"));
    Assert.True(!File.Exists(t.At(".config/mise/conf.d/wsl.toml")), "wsl.toml は WSL 以外で配置しない");
    var configs = t.Run([TestHome.MiseBin, "config", "ls", "--json"], cwd: t.Home);
    Assert.Contains("conf.d/linux.toml", configs.Stdout);
    Assert.Contains("config.toml", configs.Stdout);
  }

  [Fact]
  public void ConflictingFilesRequireForce()
  {
    var target = t.At(".bashrc");
    File.WriteAllText(target, "# keep my settings\n");
    var result = t.Mise(["dotfiles", "apply", "--yes"], check: false);
    Assert.True(result.ExitCode != 0, "競合があるのに成功した");
    Assert.Equal("# keep my settings\n", File.ReadAllText(target));
    t.Mise("dotfiles", "apply", "--yes", "--force");
    Assert.True(File.ResolveLinkTarget(target, false) != null, ".bashrc がリンクに置き換わっていない");
  }

  [Fact]
  public void WslToolsAreDeployedOnlyForWsl()
  {
    var windowsHome = t.OverrideWindowsHome();
    t.Mise(["dotfiles", "apply", "--yes"], profile: "wsl");
    AssertLinksTo(t.At(".config/mise/conf.d/wsl.toml"),
      Path.Combine(TestHome.Root, "dotfiles/.config/mise/conf.d/wsl.toml"));
    AssertLinksTo(t.At(".aws/credentials"), Path.Combine(windowsHome, ".aws/credentials"));
    var tools = t.Run([TestHome.MiseBin, "ls", "--current", "--json"], cwd: t.Home);
    using var json = JsonDocument.Parse(tools.Stdout);
    Assert.True(json.RootElement.TryGetProperty("github:mame/wsl2-ssh-agent", out _), "wsl2-ssh-agent が tools にない");

    // 手元の private なファイルは --force なしで置き換えない。
    var kube = t.At(".kube/config");
    File.Delete(kube);
    File.WriteAllText(kube, "private config\n");
    var result = t.Mise(["dotfiles", "apply", "--yes"], check: false, profile: "wsl");
    Assert.True(result.ExitCode != 0, "競合があるのに成功した");
    Assert.Equal("private config\n", File.ReadAllText(kube));
  }

  [Fact]
  public void UbuntuPackages()
  {
    var result = t.Mise("bootstrap", "packages", "status", "--json");
    Assert.Contains("libicu78", result.Stdout);
  }

  [Fact]
  public void DryRunDoesNotDeployFiles()
  {
    t.Mise("bootstrap", "--only", "dotfiles", "--dry-run");
    Assert.True(!File.Exists(t.At(".bashrc")), "dry-run で .bashrc が配置された");
    Assert.True(!File.Exists(t.At(".config/mise/config.toml")), "dry-run で config.toml が配置された");
  }

  [Fact]
  public void SetupEntrypointWithoutNix()
  {
    var bin = Directory.CreateDirectory(t.At(".local/bin")).FullName;
    File.CreateSymbolicLink(Path.Combine(bin, "mise"), TestHome.MiseBin);
    t.Run(["bash", "setup.sh", "bootstrap", "--link-only", "--dry-run"]);
    Assert.True(!File.Exists(t.At(".bashrc")), "dry-run で .bashrc が配置された");
  }

  [Fact]
  public void InteractiveBashHasMiseAndKrewPath()
  {
    t.Mise("dotfiles", "apply", "--yes");
    t.WriteExecutable(".local/bin/mise", "#!/bin/bash\necho \"export TEST_MISE_ACTIVATED=yes\"\n");
    t.Run(["bash", "--noprofile", "--rcfile", t.At(".bashrc"), "-ic",
      "[[ \"$TEST_MISE_ACTIVATED\" == yes && \":$PATH:\" == *\":$HOME/.krew/bin:\"* ]]"]);
  }

  [Fact]
  public void BootstrapRejectsIncompatibleFlags()
  {
    string[][] cases = [["--update", "--dry-run"], ["--update", "--link-only"], ["--update-only"], ["--unknown"]];
    foreach (var flags in cases)
    {
      var result = t.Run(["bash", "setup.sh", "bootstrap", .. flags], check: false);
      Assert.True(result.ExitCode != 0, $"{string.Join(' ', flags)} が拒否されなかった");
      Assert.True(!result.Stderr.Contains("Nix が見つかりません"), "Nix の有無を確認している");
    }
  }

  static void AssertLinksTo(string link, string expected) =>
    Assert.Equal(Path.GetFullPath(expected), File.ResolveLinkTarget(link, true)?.FullName);

  [Fact]
  public void KrewInstallIsIdempotent()
  {
    // krew のスタブ: list は導入済み一覧を返し、install は追記する。
    t.WriteExecutable("bin/krew",
      "#!/bin/bash\nif [[ \"$1\" == list ]]; then cat \"$HOME/plugins\" 2>/dev/null; else echo \"$2\" >> \"$HOME/plugins\"; fi\n");
    t.Env["PATH"] = $"{t.At("bin")}:/usr/bin:/bin";
    t.Mise("run", "--skip-tools", "krew:install");
    t.Mise("run", "--skip-tools", "krew:install");
    Assert.Equal(9, File.ReadAllLines(t.At("plugins")).Length);
  }
}

sealed record RunResult(int ExitCode, string Stdout, string Stderr);

sealed class TestHome : IDisposable
{
  public static readonly string Root = Path.GetFullPath(Path.Combine(Path.GetDirectoryName(ThisFile())!, ".."));
  public static readonly string MiseBin = Environment.GetEnvironmentVariable("TEST_MISE_BIN") ?? FindOnPath("mise")
    ?? throw new Exception("mise 2026.10.14 以上、または TEST_MISE_BIN の指定が必要です");

  public string Home { get; }
  public Dictionary<string, string> Env { get; }

  public TestHome()
  {
    Home = Directory.CreateTempSubdirectory("dotfiles-test-").FullName;
    Env = Environment.GetEnvironmentVariables().Cast<System.Collections.DictionaryEntry>()
      .Select(e => ((string)e.Key, (string)e.Value!))
      .Where(e => !e.Item1.StartsWith("MISE_") && !e.Item1.StartsWith("__MISE")
               && !e.Item1.StartsWith("DOTNET") && !e.Item1.StartsWith("XDG_"))
      .ToDictionary(e => e.Item1, e => e.Item2);
    Env["HOME"] = Home;
    Env["PATH"] = "/usr/bin:/bin";
    Env["XDG_CONFIG_HOME"] = At(".config");
    Env["XDG_DATA_HOME"] = At(".local/share");
    Env["XDG_CACHE_HOME"] = At(".cache");
    Env["XDG_STATE_HOME"] = At(".local/state");
    Env["MISE_TRUSTED_CONFIG_PATHS"] = $"{Root}:{Home}";
    Env["MISE_OFFLINE"] = "true";

    // [bootstrap.repos] で取得するリンク元の代わり。
    var theme = At(".local/share/dotfiles/eza-themes/themes/tokyonight.yml");
    Directory.CreateDirectory(Path.GetDirectoryName(theme)!);
    File.WriteAllText(theme, "colors: {}\n");
    Directory.CreateDirectory(At(".local/share/dotfiles/lazyvim-starter"));
  }

  public string At(string relative) => Path.Combine(Home, relative);

  public void WriteExecutable(string relative, string content)
  {
    var path = At(relative);
    Directory.CreateDirectory(Path.GetDirectoryName(path)!);
    File.WriteAllText(path, content);
    File.SetUnixFileMode(path, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute
      | UnixFileMode.GroupRead | UnixFileMode.GroupExecute | UnixFileMode.OtherRead | UnixFileMode.OtherExecute);
  }

  /// <summary>Windows ホームを一時ディレクトリに向ける mise.wsl.local.toml を置く。</summary>
  public string OverrideWindowsHome()
  {
    var local = Path.Combine(Root, "ubuntu/mise/conf.d/wsl/mise.wsl.local.toml");
    if (File.Exists(local)) Assert.Skip($"{local} が存在するため上書きしません");
    var windowsHome = At("windows");
    string[] names = [".aws/credentials", ".kube/config"];
    foreach (var name in names)
    {
      var source = Path.Combine(windowsHome, name);
      Directory.CreateDirectory(Path.GetDirectoryName(source)!);
      File.WriteAllText(source, "test\n");
    }
    File.WriteAllText(local, "[dotfiles]\n" + string.Concat(
      names.Select(name => $"\"~/{name}\" = \"{Path.Combine(windowsHome, name)}\"\n")));
    cleanup.Add(() => File.Delete(local));
    return windowsHome;
  }

  public RunResult Mise(params string[] args) => Mise(args, check: true);

  public RunResult Mise(string[] args, bool check = true, string? profile = null)
  {
    string[] environment = profile == null ? [] : ["-E", profile];
    return Run([MiseBin, "-C", Path.Combine(Root, "ubuntu"), .. environment, .. args], check);
  }

  public RunResult Run(string[] command, bool check = true, string? cwd = null)
  {
    var psi = new ProcessStartInfo(command[0])
    {
      WorkingDirectory = cwd ?? Root,
      RedirectStandardOutput = true,
      RedirectStandardError = true,
    };
    foreach (var arg in command.Skip(1)) psi.ArgumentList.Add(arg);
    psi.Environment.Clear();
    foreach (var (key, value) in Env) psi.Environment[key] = value;

    using var process = Process.Start(psi)!;
    var stdout = process.StandardOutput.ReadToEndAsync();
    var stderr = process.StandardError.ReadToEndAsync();
    if (!process.WaitForExit(60_000))
    {
      process.Kill(true);
      throw new Exception($"60 秒以内に終了しなかった: {string.Join(' ', command)}");
    }
    var result = new RunResult(process.ExitCode, stdout.Result, stderr.Result);
    if (check && result.ExitCode != 0)
      throw new Exception($"終了コード {result.ExitCode}: {string.Join(' ', command)}\n{result.Stdout}{result.Stderr}");
    return result;
  }

  public void Dispose()
  {
    foreach (var action in cleanup) action();
    Directory.Delete(Home, recursive: true);
  }

  readonly List<Action> cleanup = [];

  static string ThisFile([CallerFilePath] string path = "") => path;

  static string? FindOnPath(string name) =>
    (Environment.GetEnvironmentVariable("PATH") ?? "").Split(':')
      .Select(dir => Path.Combine(dir, name)).FirstOrDefault(File.Exists);
}
