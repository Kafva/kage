//
// What does the declarative syntax actually do 🤨 ?
// Checkout: https://android.googlesource.com/platform/tools/base
//
// We use ONE build.gradle file, we only have one module.

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.jetbrains.kotlin.android)
    // Enable dagger.hilt plugin
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
    // Enable compose plugin: https://developer.android.com/develop/ui/compose/compiler
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "one.kafva.kage"
    compileSdk = 35

    defaultConfig {
        applicationId = "one.kafva.kage"
        minSdk = 35
        targetSdk = 35
        versionCode = 1
        versionName = "0.2.1" // XXX: Keep in sync manually

        vectorDrawables {
            useSupportLibrary = true
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = "kage"
            storeFile = file("kage.jks")
            // Default password from tools/genkey
            keyPassword = "password"
            storePassword = "password"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("release")
        }
    }

    sourceSets {
        getByName("main") {
            // Location to look for jniLibs in
            jniLibs.srcDirs("build/jniLibs")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }

    lint {
        baseline = file("lint-baseline.xml")
    }
}

task<Exec>("rebuildCore") {
    // https://docs.gradle.org/current/userguide/build_lifecycle.html
    doFirst {
        commandLine("make", "-C", "${project.rootDir}/../core", "android")
    }
}

task<Exec>("setVersion") {
    doFirst {
        commandLine("${project.rootDir}/tools/setversion.sh",
                    "${project.rootDir}/src/main/res/values/version.xml")
    }
}

// Automatically rebuild core library during gradle build.
// NOTE: if you run `build` and `installDebug` in the same invocation the
// .so is generally not copied into place in time, run `build` and
// `installDebug` separately to ensure that changes appear on target.
tasks.named("build") {
    dependsOn("rebuildCore")
    dependsOn("setVersion")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewModelCompose)
    implementation(libs.androidx.lifecycle.runtime.compose)

    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    // Source: https://android.googlesource.com/platform/frameworks/support
    // Icons: https://developer.android.com/reference/kotlin/androidx/compose/material/icons/package-summary
    // More icons: https://composeicons.com/

    implementation(libs.androidx.material3)
    // You can declare dependencies in gradle scripts like this:
    //
    //                             <group>          :<name>:<version>
    //  androidTestImplementation("androidx.test.ext:junit:1.1.5")
    //  <=>
    //  (libs.version.toml) +
    //  androidTestImplementation(libs.androidx.junit)
    //
    // However, the syntax with a version catalog reference 'libs'
    // is preferred, the <group>, <name> and <version> are in this case instead
    // defined gradle/*libs*.version.toml.
    debugImplementation(libs.androidx.ui.tooling)
    implementation(libs.androidx.datastore)

    // dagger.hilt
    implementation(libs.androidx.hilt.navigation.compose)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
}

