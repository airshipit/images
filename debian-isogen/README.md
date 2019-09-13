# airship-isogen
Iso creation tool

Prepare

$(BUILD_DIR)=/some_path...
mkdir $(BUILD_DIR)

If you don't have isogen image

make build_isogen


Usage

cp examples/user-data $(BUILD_DIR)
cp examples/isogen.yaml $(BUILD_DIR)
cp examples/network-config $(BUILD_DIR)
#Modify files if necessary

docker run \
    --rm  \
    -e BUILDER_CONFIG=/config/isogen.yaml \
    -v $(shell realpath $(BUILD_DIR)):/config/ \
    $(shell cat $(BUILD_DIR)/image_id)

Get debian-custom.iso from dir $(BUILD_DIR)
