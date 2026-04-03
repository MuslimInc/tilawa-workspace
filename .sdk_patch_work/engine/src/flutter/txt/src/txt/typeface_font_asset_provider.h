// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TYPEFACE_FONT_ASSET_PROVIDER_H_
#define FLUTTER_TXT_SRC_TXT_TYPEFACE_FONT_ASSET_PROVIDER_H_

#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "txt/font_asset_provider.h"

namespace txt {

class TypefaceFontStyleSet : public SkFontStyleSet {
 public:
  TypefaceFontStyleSet();

  ~TypefaceFontStyleSet() override;

  bool registerTypeface(sk_sp<SkTypeface> typeface);

  // |SkFontStyleSet|
  int count() override;

  // |SkFontStyleSet|
  void getStyle(int index, SkFontStyle* style, SkString* name) override;

  // |SkFontStyleSet|
  sk_sp<SkTypeface> createTypeface(int index) override;

  // |SkFontStyleSet|
  sk_sp<SkTypeface> matchStyle(const SkFontStyle& pattern) override;

 private:
  std::unordered_set<uint32_t> registered_typeface_ids_;
  std::vector<sk_sp<SkTypeface>> typefaces_;

  FML_DISALLOW_COPY_AND_ASSIGN(TypefaceFontStyleSet);
};

class TypefaceFontAssetProvider : public FontAssetProvider {
 public:
  TypefaceFontAssetProvider();
  ~TypefaceFontAssetProvider() override;

  bool RegisterTypeface(sk_sp<SkTypeface> typeface);

  bool RegisterTypeface(sk_sp<SkTypeface> typeface,
                        const std::string& family_name_alias);

  // |FontAssetProvider|
  size_t GetFamilyCount() const override;

  // |FontAssetProvider|
  std::string GetFamilyName(int index) const override;

  // |FontAssetProvider|
  sk_sp<SkFontStyleSet> MatchFamily(const std::string& family_name) override;

 private:
  std::unordered_map<std::string, sk_sp<TypefaceFontStyleSet>>
      registered_families_;
  std::vector<std::string> family_names_;

  FML_DISALLOW_COPY_AND_ASSIGN(TypefaceFontAssetProvider);
};

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TYPEFACE_FONT_ASSET_PROVIDER_H_
