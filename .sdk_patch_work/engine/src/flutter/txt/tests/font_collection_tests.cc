// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gtest/gtest.h"

#include <sstream>

#include "runtime/test_font_data.h"
#include "txt/font_collection.h"
#include "txt/typeface_font_asset_provider.h"

namespace txt {
namespace testing {

class FontCollectionTests : public ::testing::Test {
 public:
  FontCollectionTests() {}

  void SetUp() override {}
};

TEST_F(FontCollectionTests, SettingUpDefaultFontManagerClearsCache) {
  FontCollection font_collection;
  sk_sp<skia::textlayout::FontCollection> sk_font_collection =
      font_collection.CreateSktFontCollection();
  ASSERT_EQ(sk_font_collection->getFallbackManager().get(), nullptr);
  font_collection.SetupDefaultFontManager(0);
  sk_font_collection = font_collection.CreateSktFontCollection();
  ASSERT_NE(sk_font_collection->getFallbackManager().get(), nullptr);
}

TEST_F(FontCollectionTests,
       ClearingFontFamilyCacheIsDeferredUntilNextParagraphBuild) {
  FontCollection font_collection;
  sk_sp<skia::textlayout::FontCollection> sk_font_collection =
      font_collection.CreateSktFontCollection();

  font_collection.ClearFontFamilyCache();

  EXPECT_TRUE(font_collection.font_family_cache_dirty_);
  EXPECT_EQ(font_collection.skt_collection_.get(), sk_font_collection.get());
  EXPECT_EQ(font_collection.CreateSktFontCollection().get(),
            sk_font_collection.get());
  EXPECT_FALSE(font_collection.font_family_cache_dirty_);
}

TEST_F(FontCollectionTests, GetUnicodeReturnsSharedInstance) {
  FontCollection font_collection;
  const sk_sp<SkUnicode> unicode = font_collection.GetUnicode();

  EXPECT_NE(unicode.get(), nullptr);
  EXPECT_EQ(font_collection.GetUnicode().get(), unicode.get());
  EXPECT_EQ(font_collection.unicode_.get(), unicode.get());
}

TEST_F(FontCollectionTests, TypefaceFontAssetProviderDeduplicatesTypeface) {
  std::vector<sk_sp<SkTypeface>> typefaces = flutter::GetTestFontData();
  ASSERT_FALSE(typefaces.empty());
  ASSERT_NE(typefaces.front(), nullptr);

  TypefaceFontAssetProvider provider;
  EXPECT_TRUE(provider.RegisterTypeface(typefaces.front(), "test_family"));
  EXPECT_FALSE(provider.RegisterTypeface(typefaces.front(), "test_family"));

  EXPECT_EQ(provider.GetFamilyCount(), 1u);
  sk_sp<SkFontStyleSet> style_set = provider.MatchFamily("TEST_FAMILY");
  ASSERT_NE(style_set, nullptr);
  EXPECT_EQ(style_set->count(), 1);
}
}  // namespace testing
}  // namespace txt
