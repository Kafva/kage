//
// What does the declarative syntax actually do 🤨 ? 
// Checkout: https://android.googlesource.com/platform/tools/base
//

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.jetbrains.kotlin.android)
}

android {
    namespace = "kafva.kage"
    compileSdk = 34
    // XXX: Explicitly set the NDK version
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "kafva.kage"
        minSdk = 34
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

}

task<Exec>("rebuildCore") {
    // https://docs.gradle.org/current/userguide/build_lifecycle.html
    doFirst {
        commandLine("${project.rootDir}/../core/build.sh", "android")
    }
}

// Automatically rebuild core library during gradle build.
// NOTE: if you run `build` and `installDebug` in the same invocation the
// .so is generally not copied into place in time, run `build` and 
// `installDebug` separately to ensure that changes appear on target.
tasks.named("build") { dependsOn("rebuildCore") }

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    testImplementation(libs.junit)
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
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}
