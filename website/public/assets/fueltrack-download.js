(function () {
  var metaUrl = "/fueltrack/release.json?v=" + Date.now();
  fetch(metaUrl)
    .then(function (res) {
      if (!res.ok) throw new Error("release.json unavailable");
      return res.json();
    })
    .then(function (data) {
      document.querySelectorAll("[data-ft-version]").forEach(function (el) {
        el.textContent = "v" + data.versionName;
      });
      var apk = document.getElementById("ftApkDownload");
      if (apk && data.apkUrl) apk.href = data.apkUrl;
      var obt = document.getElementById("ftObtainium");
      if (obt && data.obtainiumUrl) obt.href = data.obtainiumUrl;
      var rel = document.getElementById("ftReleasePage");
      if (rel && data.releasePageUrl) rel.href = data.releasePageUrl;
    })
    .catch(function () {});
})();
